FROM continuumio/miniconda3:4.10.3
LABEL authors="Ayorinde Afolayan; Erkison Odih" \
      description="Docker image for ONT assembly pipeline"

RUN apt update; apt install -y  gcc procps

RUN conda install mamba -n base -c conda-forge

COPY conda_environments/flye.yml /
RUN mamba env create -f /flye.yml && conda clean -a

COPY conda_environments/medaka.yml /
RUN mamba env create -f /medaka.yml && conda clean -a

COPY conda_environments/porechop_filtlong.yml /
RUN mamba env create -f /porechop_filtlong.yml && conda clean -a


ENV PATH /opt/conda/bin:/opt/conda/condabin:/opt/conda/envs/flye/bin:/opt/conda/envs/medaka/bin:/opt/conda/envs/porechop_filtlong/bin:$PATH

