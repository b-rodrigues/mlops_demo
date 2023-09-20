FROM rocker/r-ver:4.3.1

RUN apt-get update \
   && apt-get install -y --no-install-recommends \
   aspell \
   aspell-en \
   aspell-fr \
   aspell-pt-pt \
   libfontconfig1-dev \
   libglpk-dev \
   libxml2-dev \
   libcairo2-dev \
   libgit2-dev \
   default-libmysqlclient-dev \
   libpq-dev \
   libsasl2-dev \
   libsqlite3-dev \
   libssh2-1-dev \
   libxtst6 \
   libcurl4-openssl-dev \
   libharfbuzz-dev \
   libfribidi-dev \
   libfreetype6-dev \
   libpng-dev \
   libtiff5-dev \
   libjpeg-dev \
   libxt-dev \
   unixodbc-dev \
   pandoc

RUN mkdir /home/mlops_demo

RUN echo 'options(repos = c(REPO_NAME = "https://packagemanager.posit.co/cran/__linux__/jammy/2023-09-19"))' >> /root/.Rprofile

RUN R -e "install.packages(c('tidymodels', 'vetiver', 'targets', 'xgboost'))"

COPY _targets.R /home/mlops_demo/_targets.R

COPY functions /home/mlops_demo/functions

CMD R -e "setwd('home/mlops_demo');targets::tar_make()"
