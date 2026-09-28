---
title: Metaxy
description: Metaxy is a metadata layer for building versioned and incremental multimodal data and ML pipelines.
github_url: https://github.com/anam-org/metaxy
weight: -1
tags:
- Python
- Dagster
- Ray
- OSS
- ML
---

# Metaxy

[Metaxy](https://github.com/anam-org/metaxy) is a metadata layer for multimodal data and ML pipelines. It tracks lineage and versioning across complex computational graphs, down to individual samples, and scales to millions of them. The data itself stays where it is (for example in S3), while Metaxy manages references to it.

Its distinguishing feature is tracking and caching partial data dependencies, which leads to huge time, compute and of course money savings.

Learn more in the [docs](https://docs.metaxy.io).

---

See also:

- [Announcement post](https://anam.ai/blog/metaxy) by Anam
- [Dagster + Metaxy](https://dagster.io/blog/building-real-time-interactive-avatars-with-metaxy) by Dagster Labs
- [Docling + Slurm + Metaxy](https://georgheiler.com/2026/02/22/metaxy-dagster-slurm-multimodal/) by ASCII
