# What's Next?
<hr>
Where applicable, I included page numbers referencing the book `Cloud Native Spring in Action` by
Thomas Vitale. Note that this isn't a book focused on platform development, which is what working
with Kubernetes mainly is. However, it does provide a good overview of cloud native development,
enough to get started with Kubernetes. For those with a basic understanding of Kubernetes and 
would like to learn more advanced strategies, consider consulting books more focused towards
Kubernetes and ops-development. But for the beginner cloud explorer, it is a great book resource,
especially if you're coming from a Spring background.
<hr>

One of the main goals of this project is to create a cloud native application 
based on the 15-factor app methodology created by Kevin Hoffman, an extension of the 12-factor methodology:

1. One codebase, one application
2. **API first**
3. Dependency management
4. Design, build, release, and run
5. Configuration, credentials, and code
6. Logs
7. Disposability
8. Backing services
9. Environment parity
10. Administrative processes
11. Port binding
12. Stateless processes
13. Concurrency
14. **Telemetry**
15. **Authentication and authorization**

The bolded items are the new factors added on top of the 12-factor methodology.

During the development of the GroupHQ demo, compromises had to be made. Specifically, compromises
towards the following factors:
- Configuration, credentials, and code
- Telemetry
- Authentication and authorization

Below is a discussion of how GroupHQ tackles these factors currently, and what needs to be decided
for future development.

## Configuration, credentials, and code
For a cloud native app, a developer shouldn't need to change the code in order to change the
configuration. Configuration should be externalized, such as in a configuration repository or 
in a configuration deployment file (e.g., ConfigMap in Kubernetes). When the configuration changes,
we want our deployed services to pick up these changes and automatically restart.

There are two ways we can handle configuration in GroupHQ:

### Configuration Server
This involves creating a separate service to provide configuration to other services in the
GroupHQ system. We already have a configuration server connected to a configuration repository hosted
on GitHub; however, GroupHQ is not currently using it. If we were to use it, then we'd need to set up
a configuration refresh flow. This would involve the following (p. 489):
- Set up a webhook on GitHub to notify the configuration service when a change is made to the config repository
- Send a config change event from the configuration service to an event broker (e.g. RabbitMQ)
- Fan out the event to all services, causing them to read the new configuration from the configuration service
- Each service then refreshes its configuration if necessary (e.g., if their configuration has changed)

In this flow, it's worth using Spring Cloud Bus, which is a Spring Cloud component that allows
services to subscribe to a common queue in an event broker in order to share events with each other.
A configuration server would send a config change event through Spring Cloud Bus, which propagates it
to all services also using Spring Cloud Bus.

Since this requires significant development work and testing at several levels, an alternative approach
was taken: Kubernetes ConfigMaps.

### Kubernetes ConfigMap
Right now, configuration is handled through Kubernetes using ConfigMaps mounted as volumes.
That's a mouthful, but essentially, it means that we're using Kubernetes to store our configuration.
The configuration is stored in a ConfigMap manifest, a type of Kubernetes object. While we can use data
from a ConfigMap in command-line arguments and environment variables, this setup only occurs once.
To allow our applications to pick up changes to the ConfigMap, 
we need to mount the ConfigMap as a volume (p. 494). 
Since Kubernetes updates a container's ConfigMap, when a developer makes changes to it, 
we can use this to our advantage in the following ways (p. 499-500):

1. Use Kustomize to monitor when ConfigMaps change, and perform a rolling restart of all pods
that use the ConfigMap. This is the simplest solution, but the downside of this is that the pods 
will be restarted completely, resulting in short downtime.
2. Use Spring Cloud Kubernetes Configuration Watcher. In a Spring Boot application, it's possible 
to signal to the application that the configuration has changed, and to reload the configuration.
This is done by sending a POST request to the `/actuator/refresh` endpoint provided by 
Spring Boot Actuator. Spring Cloud Kubernetes Configuration Watcher can be configured to monitor
ConfigMaps and Secrets that are mounted as volumes, and to send a POST request to the `/actuator/refresh`
when they change. This is an improvement over this first solution since nothing is restarted as
Spring Boot will only refresh the application context based on the new configuration.
3. Spring Cloud Kubernetes Config Server. Similar to the traditional Spring Cloud Config Server
approach, this solution provides support for using ConfigMaps and Secrets as configuration sources,
along with others such as a Git repository. It's essentially an upgraded version of a Spring
Cloud Config Server that supports Kubernetes ConfigMaps and Secrets. This is the most complex
solution, but it's also the most flexible.

Currently, we follow the first approach with Kustomize, but we should consider at least the 
second approach. We could also follow the approach in the previous section with a Spring Cloud Config
Server if there is a need to use a configuration repository.

We can store secrets in Kubernetes Secrets, which are similar to ConfigMaps, except that they are 
Base64 encoded and managed separately from ConfigMaps. From the previous description, it's clear
that a Kubernetes Secret is not secure (reminder: Base64 encoding is not encryption). Thomas Vitale
puts this succinctly:
> If you remember only one thing about Secrets, make it the following: Secrets are not secret! (p. 497)

Managing secrets requires a significant amount of work to ensure that they are encrypted at rest
and able to be version-controlled. While you can store encrypted secrets in Kubernetes internal etcd
storage, it doesn't allow them to be version controlled, which can lead to confusing problems for
developers on which secrets should be used.

One solution is to use Sealed Secretes, a project introduced by Bitnami that allows you to version-control and
apply encrypted secrets safely using a `SealedSecret` object in Kubernetes, part of the Sealed Secrets project. 
How does it work? A SealedSecrets controller runs in the cluster, which uses an asymmetric key pair (one private key and 
one public key) to encrypt and decrypt secrets. The public key can be shared between developers to encrypt secrets by creating a
`SealedSecret` object, and these secrets can be safely stored outside the cluster. When the secrets need to be decrypted and mounted onto
a container's file system, the SealedSecrets controller uses its private key to decrypt the secret.
In the case of secrets stored in a third-party service, a project called External Secrets functions similarly to Sealed Secrets,
but instead supports an `ExternalSecret` object in Kubernetes (p. 498-499).

Care must be taken to ensure that access to the container's file system is restricted, otherwise an attacker could 
access the secret if they have access to the container's file system. Currently, we don't use this approach. Instead, 
we store secrets unencrypted in our cluster. This has the same security benefits as using the Sealed Secret project
(since in either case, someone with access to the cluster would be able to retrieve both the unencrypted secrets and 
the private key used by the SealedSecrets controller), but results in tedious self-management of secrets without 
the benefits of version control. In the future, we should adopt the Sealed Secret project in our cluster.


## Telemetry
Telemetry is the process of collecting data about a system. This includes metrics, logs, and traces.

Currently, GroupHQ uses the following tools for telemetry:
- Metrics: Collected in applications using Micrometer. Pulled from applications and aggregated by Prometheus.
- Logs: Collected from applications by Fluent Bit, and sent to Loki, which aggregates them.
- Traces: Collected in applications using the OpenTelemetry Java agent which ships them to Tempo.
- Dashboards: Grafana, collects logs, metrics, and traces from Prometheus, Loki, and Tempo respectively.

In production, these containers are found in pods within the `observability-stack` namespace.
When first implementing observability in GroupHQ, we initially tried to use Micrometer Tracing with the 
Micrometer Observation API. However, due to its complexity, especially with reactive applications, that initiative
has been paused for now. You can see a discussion on the initial observability strategy [in this PR](https://github.com/GroupHQ/group-service/pull/10).
The initial strategy was replaced with a simpler strategy due to the benefits of having logs collected by another application
instead of having the applications responsible for collecting and sending their own logs. This strategy was taken from
the book `Cloud Native Spring in Action` by Thomas Vitale. You can find their observability guide from their repository
[here](https://github.com/ThomasVitale/cloud-native-spring-in-action/blob/main/Guides/grafana-observability-stack/README.md).
To view the latest development on the observability strategy, [check out this PR](https://github.com/GroupHQ/group-service/pull/12).

In the future, we should consider implementing the Micrometer Tracing with the Micrometer Observation API strategy.

Side note: A curious observation worth pointing out is that the two observability strategies that we've tried so far 
produce different trace steps. The first strategy (taken from the Spring Blog [Observability with Spring Boot 3](https://spring.io/blog/2022/10/12/observability-with-spring-boot-3))
produces trace steps that are based on observations recorded through the Micrometer Observation API. This usually shows
traces from library code that utilize the observation API, such as Spring Security, but it does not show method calls,
unlike the second approach. The second approach (taken from the book `Cloud Native Spring in Action`) produces trace steps
that are based on method calls. Observations through the Micrometer Observation API are not recorded. 
It would be nice to have a combination of both approaches. Further work is needed to be done to understand how both 
approaches work and how we can add steps to our trace without introducing too much code complexity.

## Authentication and authorization
We don't really use authentication and authorization in GroupHQ, but we also don't allow
any sensitive actions. Users can only join or leave groups. They can't create or delete groups.
Group ownership is defined by the user who doesn't have any identifiable information, so even
if someone knows a user's ID, they can't do anything damaging with it.

This is good for now, but GroupHQ will need a better authentication and authorization strategy
for future development. It _had_ one, but unfortunately, it had to be removed from the project
timeline due to the unnecessary complexity it added to the GroupHQ demo.

As for the demo itself, one security requirement that should have been implemented is requiring
authentication for the `/actuator` endpoints _within_ the Kubernetes cluster (p. 457). To clarify, the actuator
endpoint on Edge Service which is the only application exposed to the user has the `/actuator` endpoints
secured. It's the internal services: Group Service, Group Sync, Config Service, that allow
unsecured communication with each other to the `/actuator` endpoint. This violates the zero-trust 
principle. If somehow the cluster is compromised, an attacker could access the `/actuator` endpoints 
on these unsecured services and perform sensitive actions.

## Additional Thoughts
1. We currently use Kustomize to apply patches to base Kubernetes manifests. This is a good start, 
but for more advanced deployments, we should keep in mind more advanced tools such as Helm 
(support for templates, often used with Kustomize patches) and ytt (supports both templates
and patches).
2. We currently use the commit hash as the image tag for our Docker images. It works, but it's not
very user-friendly in conveying how recent or old a version is, or how significant of a change
one can expect between versions. We should consider implementing a combination of semantic versioning for 
conveying the significance of a change, and calendar versioning for conveying how recent or old a 
version is, while still incorporating the commit hash to uniquely identify release candidates.
3. We don't have an actual staging environment. We also don't have any non-functional tests. 
We should consider implementing these and automating their execution as part of our CI/CD 
pipeline once a release candidate is created. Once a staging environment is created, we can
host our Group Sync tests on there, since they require a running instance of Group Service,
and we don't want to rely on a production instance of Group Service for testing.
4. Each cloud provider has a different way of interacting with and managing Kubernetes deployments.
To prevent having to learn each cloud provider's way of doing things, we should consider using
a tool such as Terraform or Crossplane to manage our Kubernetes deployments. Either service
integrates with cloud providers through a provider plugin, and allows us to define our Kubernetes
deployments in a cloud-agnostic way, preventing vendor lock-in.
5. On our current cloud provider, the Postgres user, Redis user, and RabbitMQ user credentials
that are stored in the environment for our applications have been given admin privileges. We should
change this to only give them the privileges they need to perform their tasks.
6. We currently ask for a fixed number of replicas for our services. Instead, we should consider
using the Horizontal Pod Autoscaler (HPA) to scale our services based on CPU and memory usage.
To prevent high-costs, we should explore ways to limit the maximum number of replicas that can be
created by the HPA.
7. Currently, production deployments are done following the _rolling update_ strategy. There are 
other strategies to keep in mind, such as blue/green deployments and canary releases. Though they're
not necessary for the demo considering the current scope of the project.
8. The nature of data usefulness in GroupHQ is ephemeral. Once a group is expired, we don't need
to query it anymore. Because of this, we may benefit from periodically moving older data to an analytics-optimized
platform for longer-term storage and analysis, lessening the amount of storage we need to allocate for our database.
9. We currently use PostgreSQL to store our group data. In a Cloud Native ecosystem, relational databases can vertically
scale to meet demand, and they do a good job of it. However, only having one database instance means that we have a single
point of failure risk. Replicating the database is a solution, but that comes at the cost of consistency in exchange
for partition tolerance (CAP theorem: Consistency, Availability, Partition Tolerance). Horizontally scaling a relational
database is not a simple task, since there is no native support for horizontal scaling unlike NoSQL databases. Typically, 
such horizontal scaling is achieved through the well-known primary-replica approach, where a primary database is used for 
writing and synchronously or asynchronously updates the read-only replica databases. Nevertheless, this issue is complex 
to solve, and whether it's worth solving depends on how well our relational database can handle the current demand.
Therefore, we should employ a monitoring solution to keep track of our database's performance and to alert us when
it's struggling to meet demand.