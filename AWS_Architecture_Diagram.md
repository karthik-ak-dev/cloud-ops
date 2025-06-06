# AWS Cloud-Ops Architecture Diagram

## Complete AWS Infrastructure Architecture

```
                                    ┌─────────────────────────────────────────────────────────────────┐
                                    │                      INTERNET                                   │
                                    └─────────────────────────┬───────────────────────────────────────┘
                                                              │
                                    ┌─────────────────────────┴───────────────────────────────────────┐
                                    │                 GITHUB ACTIONS CI/CD                            │
                                    │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
                                    │  │   Workflow      │ │  Image Build    │ │   Deploy to     │    │
                                    │  │   Triggers      │ │  & Push to ECR  │ │   EKS Cluster   │    │
                                    │  └─────────────────┘ └─────────────────┘ └─────────────────┘    │
                                    └─────────────────────────┬───────────────────────────────────────┘
                                                              │
┌───────────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────┐
│                                              AWS CLOUD (Multi-Region Support)                                             │
│                                                                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                            VPC (10.0.0.0/16)                                                        │  │
│  │                                                                                                                     │  │
│  │  ┌─────────────────────────────────────┐                    ┌─────────────────────────────────────┐                 │  │
│  │  │           AVAILABILITY ZONE A       │                    │           AVAILABILITY ZONE B       │                 │  │
│  │  │                                     │                    │                                     │                 │  │
│  │  │  ┌─────────────────────────────────┐│                    │┌─────────────────────────────────┐  │                 │  │
│  │  │  │      PUBLIC SUBNET A            ││                    ││      PUBLIC SUBNET B            │  │                 │  │
│  │  │  │  ┌─────────────────────────────┐││                    ││┌─────────────────────────────┐  │  │                 │  │
│  │  │  │  │     Internet Gateway        │││                    │││     Application Load        │  │  │                 │  │
│  │  │  │  │                             │││                    │││     Balancer (ALB)          │  │  │                 │  │
│  │  │  │  └─────────────────────────────┘││                    ││└─────────────────────────────┘  │  │                 │  │
│  │  │  │                                 ││                    ││                                 │  │                 │  │
│  │  │  │  ┌─────────────────────────────┐││                    ││┌─────────────────────────────┐  │  │                 │  │
│  │  │  │  │     NAT Gateway             │││                    │││     NAT Gateway             │  │  │                 │  │
│  │  │  │  └─────────────────────────────┘││                    ││└─────────────────────────────┘  │  │                 │  │
│  │  │  └─────────────────────────────────┘│                    │└─────────────────────────────────┘  │                 │  │
│  │  │                                     │                    │                                     │                 │  │
│  │  │  ┌─────────────────────────────────┐│                    │┌─────────────────────────────────┐  │                 │  │
│  │  │  │     PRIVATE SUBNET A            ││                    ││     PRIVATE SUBNET B            │  │                 │  │
│  │  │  │                                 ││                    ││                                 │  │                 │  │
│  │  │  │ ┌─────────────────────────────┐ ││                    ││ ┌─────────────────────────────┐ │  │                 │  │
│  │  │  │ │    EKS WORKER NODES         │ ││                    ││ │    EKS WORKER NODES         │ │  │                 │  │
│  │  │  │ │  ┌─────────────────────────┐│ ││                    ││ │┌─────────────────────────┐  │ │  │                 │  │
│  │  │  │ │  │    MICROSERVICES        ││ ││                    ││ ││    MICROSERVICES        │  │ │  │              │  │
│  │  │  │ │  │  - API Services         ││ ││                    ││ ││  - API Services         │  │ │  │              │  │
│  │  │  │ │  │  - Web Services         ││ ││                    ││ ││  - Web Services         │  │ │  │              │  │
│  │  │  │ │  │  - Background Jobs      ││ ││                    ││ ││  - Background Jobs      │  │ │  │              │  │
│  │  │  │ │  │  (IRSA Integration)     ││ ││                    ││ ││  (IRSA Integration)     │  │ │  │              │  │
│  │  │  │ │  └─────────────────────────┘│ ││                    ││ │└─────────────────────────┘  │ │  │              │  │
│  │  │  │ └─────────────────────────────┘ ││                    ││ └─────────────────────────────┘ │  │              │  │
│  │  │  │                                 ││                    ││                                 │  │              │  │
│  │  │  │ ┌─────────────────────────────┐ ││                    ││ ┌─────────────────────────────┐ │  │              │  │
│  │  │  │ │  AURORA POSTGRES INSTANCE   │ ││                    ││ │  AURORA POSTGRES INSTANCE   │ │  │              │  │
│  │  │  │ │      (Multi-AZ)             │ ││                    ││ │      (Multi-AZ)             │ │  │              │  │
│  │  │  │ └─────────────────────────────┘ ││                    ││ └─────────────────────────────┘ │  │              │  │
│  │  │  │                                 ││                    ││                                 │  │              │  │
│  │  │  │ ┌─────────────────────────────┐ ││                    ││ ┌─────────────────────────────┐ │  │              │  │
│  │  │  │ │   REDIS ELASTICACHE         │ ││                    ││ │   REDIS ELASTICACHE         │ │  │              │  │
│  │  │  │ │      (Multi-AZ)             │ ││                    ││ │      (Multi-AZ)             │ │  │              │  │
│  │  │  │ └─────────────────────────────┘ ││                    ││ └─────────────────────────────┘ │  │              │  │
│  │  │  └─────────────────────────────────┘│                    │└─────────────────────────────────┘  │              │  │
│  │  └─────────────────────────────────────┘                    └─────────────────────────────────────┘              │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                     MANAGED AWS SERVICES                                                             │  │
│  │                                                                                                                     │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐              │  │
│  │  │  ELASTIC CONTAINER  │  │   AURORA POSTGRES   │  │   VALKEY/REDIS      │  │       IAM           │              │  │
│  │  │    REGISTRY (ECR)   │  │    SERVERLESS       │  │    SERVERLESS       │  │   ROLES & IRSA      │              │  │
│  │  │                     │  │                     │  │                     │  │                     │              │  │
│  │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │              │  │
│  │  │ │  Services Repo  │ │  │ │   Auto-scaling  │ │  │ │   Auto-scaling  │ │  │ │ App Full Access │ │              │  │
│  │  │ │  Multi-service  │ │  │ │   Multi-AZ      │ │  │ │   Multi-AZ      │ │  │ │ EKS Node Group  │ │              │  │
│  │  │ │  Image Storage  │ │  │ │   Backup/Point  │ │  │ │   High Avail.   │ │  │ │ ALB Controller  │ │              │  │
│  │  │ └─────────────────┘ │  │ │   in Time Rec.  │ │  │ └─────────────────┘ │  │ │ CI/CD Roles     │ │              │  │
│  │  └─────────────────────┘  │ └─────────────────┘ │  └─────────────────────┘  │ └─────────────────┘ │              │  │
│  │                           └─────────────────────┘                           └─────────────────────┘              │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                    EKS CONTROL PLANE                                                                │  │
│  │                                                                                                                     │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐              │  │
│  │  │   KUBERNETES API    │  │  AWS LOAD BALANCER  │  │   CLUSTER AUTO-     │  │    OIDC PROVIDER    │              │  │
│  │  │      SERVER         │  │     CONTROLLER      │  │     SCALER          │  │    (IRSA SUPPORT)   │              │  │
│  │  │                     │  │                     │  │                     │  │                     │              │  │
│  │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │              │  │
│  │  │ │  Multi-AZ       │ │  │ │  Auto ALB/NLB   │ │  │ │  Node Scaling   │ │  │ │ Pod-level AWS   │ │              │  │
│  │  │ │  High Avail.    │ │  │ │  Creation       │ │  │ │  Based on       │ │  │ │ Permissions     │ │              │  │
│  │  │ │  Control Plane  │ │  │ │  Ingress Mgmt   │ │  │ │  Workload       │ │  │ │ No Hardcoded    │ │              │  │
│  │  │ └─────────────────┘ │  │ └─────────────────┘ │  │ └─────────────────┘ │  │ │ Credentials     │ │              │  │
│  │  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘  │ └─────────────────┘ │              │  │
│  │                                                                             └─────────────────────┘              │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

```

## Environment Architecture (Dev/Prod)

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                              MULTI-ENVIRONMENT SETUP                                     │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐    │
│  │          DEV ENVIRONMENT            │    │         PROD ENVIRONMENT            │    │
│  │                                     │    │                                     │    │
│  │ ┌─────────────────────────────────┐ │    │ ┌─────────────────────────────────┐ │    │
│  │ │         TERRAFORM               │ │    │ │         TERRAFORM               │ │    │
│  │ │      environments/dev/          │ │    │ │      environments/prod/         │ │    │
│  │ │                                 │ │    │ │                                 │ │    │
│  │ │ • Smaller instance sizes        │ │    │ │ • Production instance sizes     │ │    │
│  │ │ • Lower capacity settings       │ │    │ │ • Higher capacity settings      │ │    │
│  │ │ • Development configs           │ │    │ │ • Production configs            │ │    │
│  │ └─────────────────────────────────┘ │    │ └─────────────────────────────────┘ │    │
│  │                                     │    │                                     │    │
│  │ ┌─────────────────────────────────┐ │    │ ┌─────────────────────────────────┐ │    │
│  │ │           HELM VALUES           │ │    │ │           HELM VALUES           │ │    │
│  │ │        values/dev/              │ │    │ │        values/prod/             │ │    │
│  │ │                                 │ │    │ │                                 │ │    │
│  │ │ • Development service configs   │ │    │ │ • Production service configs    │ │    │
│  │ │ • Lower resource limits         │ │    │ │ • Higher resource limits        │ │    │
│  │ │ • Debug enabled                 │ │    │ │ • Optimized for performance     │ │    │
│  │ └─────────────────────────────────┘ │    │ └─────────────────────────────────┘ │    │
│  │                                     │    │                                     │    │
│  │ ┌─────────────────────────────────┐ │    │ ┌─────────────────────────────────┐ │    │
│  │ │        MICROSERVICES            │ │    │ │        MICROSERVICES            │ │    │
│  │ │                                 │ │    │ │                                 │ │    │
│  │ │ • {service}-dev namespaces      │ │    │ │ • {service}-prod namespaces     │ │    │
│  │ │ • Development endpoints         │ │    │ │ • Production endpoints          │ │    │
│  │ │ • Testing configurations        │ │    │ │ • Performance configurations    │ │    │
│  │ └─────────────────────────────────┘ │    │ └─────────────────────────────────┘ │    │
│  └─────────────────────────────────────┘    └─────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                                   CI/CD WORKFLOW                                         │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   DEVELOPER     │    │   GITHUB        │    │   BUILD &       │    │   DEPLOY TO     ││
│  │   COMMITS       │────▶   REPOSITORY     │────▶   CONTAINER     │────▶   EKS CLUSTER  ││
│  │                 │    │                 │    │   REGISTRY      │    │                 ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘│
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐│
│  │                           GITHUB ACTIONS WORKFLOW                                  ││
│  │                                                                                     ││
│  │  1. ┌─────────────────┐  2. ┌─────────────────┐  3. ┌─────────────────┐           ││
│  │     │   Checkout      │     │   Update Helm   │     │   Configure     │           ││
│  │     │   Repository    │────▶│   Values with   │────▶│   AWS & kubectl │           ││
│  │     │                 │     │   New Image Tag │     │                 │           ││
│  │     └─────────────────┘     └─────────────────┘     └─────────────────┘           ││
│  │                                                                                     ││
│  │  4. ┌─────────────────┐  5. ┌─────────────────┐  6. ┌─────────────────┐           ││
│  │     │   Create        │     │   Deploy/Update │     │   Verify        │           ││
│  │     │   Namespace     │────▶│   with Helm     │────▶│   Deployment    │           ││
│  │     │                 │     │                 │     │                 │           ││
│  │     └─────────────────┘     └─────────────────┘     └─────────────────┘           ││
│  └─────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐│
│  │                             WORKFLOW INPUTS                                        ││
│  │                                                                                     ││
│  │  • Service Name (which microservice to deploy)                                     ││
│  │  • Environment (dev/prod)                                                          ││
│  │  • Image Tag (version to deploy)                                                   ││
│  │  • AWS Region                                                                      ││
│  │  • Project Name (cluster identification)                                           ││
│  └─────────────────────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

## Security & IRSA Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                      SECURITY & IAM ROLES FOR SERVICE ACCOUNTS                          │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐│
│  │                              IRSA FLOW                                             ││
│  │                                                                                     ││
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                ││
│  │  │   KUBERNETES    │    │   OIDC          │    │   AWS IAM       │                ││
│  │  │   SERVICE       │────▶   PROVIDER      │────▶   ROLE          │                ││
│  │  │   ACCOUNT       │    │   (EKS)         │    │                 │                ││
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘                ││
│  │           │                                              │                         ││
│  │           ▼                                              ▼                         ││
│  │  ┌─────────────────┐                            ┌─────────────────┐                ││
│  │  │   POD GETS      │                            │   AWS SERVICES  │                ││
│  │  │   TEMPORARY     │◀───────────────────────────│   ACCESS        │                ││
│  │  │   AWS CREDS     │                            │                 │                ││
│  │  └─────────────────┘                            └─────────────────┘                ││
│  └─────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐│
│  │                             IAM ROLES CREATED                                      ││
│  │                                                                                     ││
│  │  ┌─────────────────────────────────────────────────────────────────────────────────┐││
│  │  │                       app-full-access-role                                     │││
│  │  │  • Assumed by application pods via IRSA                                        │││
│  │  │  • Full AWS service access for applications                                    │││
│  │  │  • Automatic credential rotation (15 minutes)                                  │││
│  │  │  • No hardcoded credentials needed                                             │││
│  │  └─────────────────────────────────────────────────────────────────────────────────┘││
│  │                                                                                     ││
│  │  ┌─────────────────────────────────────────────────────────────────────────────────┐││
│  │  │                      eks-node-group-role                                       │││
│  │  │  • Used by EKS worker nodes                                                    │││
│  │  │  • EC2, EKS, and ECR permissions                                               │││
│  │  │  • Node-level AWS integration                                                  │││
│  │  └─────────────────────────────────────────────────────────────────────────────────┘││
│  │                                                                                     ││
│  │  ┌─────────────────────────────────────────────────────────────────────────────────┐││
│  │  │                       alb-controller-role                                      │││
│  │  │  • Used by AWS Load Balancer Controller                                        │││
│  │  │  • ALB/NLB creation and management                                             │││
│  │  │  • Ingress controller permissions                                              │││
│  │  └─────────────────────────────────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                                   DATA FLOW                                             │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   EXTERNAL      │    │   APPLICATION   │    │   CACHING       │    │   DATABASE      ││
│  │   USERS         │────▶   LOAD BALANCER │────▶   LAYER         │────▶   LAYER         ││
│  │                 │    │   (ALB)         │    │                 │    │                 ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘│
│                                   │                       │                       │      │
│                                   ▼                       ▼                       ▼      │
│                          ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│                          │   MICROSERVICES │    │   REDIS/VALKEY  │    │   AURORA        ││
│                          │   IN EKS        │    │   ELASTICACHE   │    │   POSTGRESQL    ││
│                          │                 │    │                 │    │                 ││
│                          │ • API Services  │    │ • Session Store │    │ • Primary Data  ││
│                          │ • Web Services  │    │ • Cache Layer   │    │ • ACID Compliant││
│                          │ • Background    │    │ • High Perf.    │    │ • Multi-AZ      ││
│                          │   Jobs          │    │ • Multi-AZ      │    │ • Auto Backup   ││
│                          └─────────────────┘    └─────────────────┘    └─────────────────┘│
│                                   │                                                       │
│                                   ▼                                                       │
│                          ┌─────────────────┐                                            │
│                          │   CONTAINER     │                                            │
│                          │   REGISTRY      │                                            │
│                          │   (ECR)         │                                            │
│                          │                 │                                            │
│                          │ • Multi-service │                                            │
│                          │   Image Storage │                                            │
│                          │ • Version Mgmt  │                                            │
│                          └─────────────────┘                                            │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

## Terraform Module Dependencies

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                            TERRAFORM MODULE RELATIONSHIPS                               │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│                              ┌─────────────────┐                                        │
│                              │   PROVIDERS     │                                        │
│                              │                 │                                        │
│                              │ • AWS Provider  │                                        │
│                              │ • Kubernetes    │                                        │
│                              │ • Helm Provider │                                        │
│                              └─────────┬───────┘                                        │
│                                        │                                                │
│                                        ▼                                                │
│                              ┌─────────────────┐                                        │
│                              │      VPC        │                                        │
│                              │                 │                                        │
│                              │ • Multi-AZ      │                                        │
│                              │ • Public/Private│                                        │
│                              │ • NAT Gateways  │                                        │
│                              └─────────┬───────┘                                        │
│                                        │                                                │
│                    ┌───────────────────┼───────────────────┐                          │
│                    ▼                   ▼                   ▼                          │
│          ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐                  │
│          │      EKS        │ │  AURORA-POSTGRES│ │   REDIS/VALKEY  │                  │
│          │                 │ │                 │ │                 │                  │
│          │ • Control Plane │ │ • Regular       │ │ • ElastiCache   │                  │
│          │ • Worker Nodes  │ │ • Serverless    │ │ • Serverless    │                  │
│          │ • IRSA/OIDC     │ │ • Multi-AZ      │ │ • Multi-AZ      │                  │
│          └─────────┬───────┘ └─────────────────┘ └─────────────────┘                  │
│                    │                                                                   │
│                    ▼                                                                   │
│          ┌─────────────────┐                                                           │
│          │ ALB-CONTROLLER  │                                                           │
│          │                 │                                                           │
│          │ • Helm Deploy   │                                                           │
│          │ • Service LBs   │                                                           │
│          │ • Ingress Mgmt  │                                                           │
│          └─────────────────┘                                                           │
│                    │                                                                   │
│                    ▼                                                                   │
│          ┌─────────────────┐                                                           │
│          │    CI-CD        │                                                           │
│          │                 │                                                           │
│          │ • IAM Roles     │                                                           │
│          │ • EKS Access    │                                                           │
│          │ • IRSA Config   │                                                           │
│          └─────────────────┘                                                           │
│                    │                                                                   │
│                    ▼                                                                   │
│          ┌─────────────────┐                                                           │
│          │      ECR        │                                                           │
│          │                 │                                                           │
│          │ • Container     │                                                           │
│          │   Registry      │                                                           │
│          │ • Multi-service │                                                           │
│          └─────────────────┘                                                           │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Summary

### Infrastructure Layer (Terraform)
- **VPC**: Multi-AZ networking with public/private subnets, NAT gateways, Internet gateway
- **EKS**: Kubernetes cluster with IRSA support, auto-scaling, multi-AZ worker nodes
- **Aurora PostgreSQL**: Both regular and serverless instances, multi-AZ deployment
- **Redis/Valkey**: ElastiCache and serverless caching solutions
- **ALB Controller**: Automatic load balancer provisioning for ingress
- **ECR**: Container registry for multi-service image storage
- **IAM**: Comprehensive role-based security with IRSA integration

### Application Layer (Helm/Kubernetes)
- **Microservices**: Containerized applications with reusable Helm charts
- **IRSA**: Secure AWS access without hardcoded credentials
- **Multi-Environment**: Separate dev/prod configurations and deployments
- **Load Balancing**: ALB integration for external service access
- **Auto-scaling**: Horizontal pod and cluster auto-scaling

### CI/CD Layer (GitHub Actions)
- **Automated Deployment**: Workflow-based deployments to EKS
- **Multi-Environment**: Support for dev/prod deployments
- **Image Management**: Automated image tag updates and registry pushes
- **Kubernetes Integration**: Native kubectl and Helm integration

This architecture provides a comprehensive, scalable, and secure cloud infrastructure supporting microservices deployment with best practices for security, high availability, and automated deployments. 