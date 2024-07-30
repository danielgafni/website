+++
title = "Cloud Computing with EKS: Dagster with ArgoCD"
date = 2024-06-25
draft = true

[taxonomies]
tags = ["AWS", "EKS", "Kubernetes", "DevOPS", "Terraform", "Dagster", "ArgoCD"]
[extra]
add_src_to_code_block = true

+++

In the previous part of this series, we learned how to prepare a EKS cluster for some cloud computing. Now, we are going to learn how to setup Production and Preview environments (also called Branch Deployments) to organize and streamline development of data pipelines powered by Dagster.

# What are Branch Deployments?

One of the companies I worked at called them Feature Stages. GitLab calls them [Preview Apps](https://docs.gitlab.com/ee/ci/review_apps/). In Dagster, they are known as [Branch Deployments](https://docs.dagster.io/dagster-plus/managing-deployments/branch-deployments).

Regardless of naming, the meaning of this powerful concept is the same - deploying a development version of an application to a separate environment created specifically for the git branch or Pull Request.

This DevOps methodology allows testing the entire application in an environment similar to production before merging the code to the main branch. It's extremely useful when fully automated and done right, because developers get to effortlessly test their apps without intefeiring each other and pinging Infrastructure teams.

In contrast to using, Branch Deployments traditionally require quite some work to be set up. For this reason, they are provided as Dagster+ feature.

# And why do I need to care about ArgoCD?

ArgoCD is quite an amazing piece of technology. It can easily pull off tricks which traditional CD systems will struggle to imlement. Branch Deployments is one of them.

ArgoCD has a concept of `ApplicationSet` - a template which can spawn multiple instances of `Applications`s. `ApplicationSet`s can be backed by various Generators, `pullRequest` being one of them.

The `pullRequest` Generator creates a new copy of an `Application` for currently opened Pull Requests and allows injecting information like branch name, PR ID, and commit hash into the `Application` manifest. ArgoCD will then take care of deploying the `Application` into the Kubernetes cluster.
