# Puppet Surrogate

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with surrogate](#setup)
    * [What surrogate affects](#what-surrogate-affects)
    * [Beginning with surrogate](#beginning-with-surrogate)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module allows you to install a modified version of Surrogate backup.
Surrogate is an xtrabackup based script for backing up mysql databases in a hot-backup
fashion. This means no downtime or slowdown for your database server!

Support most debian and redhat based Linux distributions and any 5.5+ version of MySQL!

For support please open an issue through the project: https://github.com/justicel/puppet-surrogate/issues

## Module Description

Implements a custom version of Surrogate backup, which was originally written from:
    
https://github.com/sixninetynine/surrogate

Additionally uses Percona Innobackup/Xtrabackup ( http://www.percona.com/doc/percona-xtrabackup/2.2/ ).
Xtrabackup allows you to do no downtime/slowdown backups for current version MySQL servers, regardless
of if they are based upon Percona code or not.

## Setup

### What surrogate affects

* Install Surrogate scripts
* Installs xtrabackup and qpress (qpress used for backup compression)
* Needs a local mysql server to run backups.

### Beginning with surrogate

Module setup simply requires installation on a puppet server or local machine with a copy of puppetlabs-stdlib
and vcsrepo modules. Additionally you'll need the percona repository, but that is installed as needed by the module.

## Usage

Setup is very simple. Example below for a very basic installation (You'll really want to read through full options):

    node 'mysql-slave' {
      class { 'surrogate':
        backup_user   => 'backup_user',
        backup_pass   => 'mysecurepassword',
        backup_folder => '/var/backups/mysql',
      }
    }

Additionally you will need to create a mysql user (DON'T USE ROOT!!!!) for backups. The backup user needs the following perms:

    SELECT
    RELOAD
    SHOW DATABASES
    LOCK TABLES
    SHOW VIEW
    REPLICATION CLIENT

You can create a user like this as needed:

    use mysql;
    GRANT SELECT, RELOAD, SHOW DATABASES, LOCK TABLES, SHOW VIEW, REPLICATION CLIENT on *.* to 'dbbackup'@'localhost' IDENTIFIED BY '<password>';

Then make sure to run a flush privileges:

    flush privileges;

Your sql server should now be ready to go

## Reference

* `surrogate`: Main installation class which governs configuration variables and source download/install
* `surrogate::cron`: Class to build out all of the cron-jobs for backups. Generally not client facing.
* `surrogate::params`: Parameters for OS specific configuration variables.

## Limitations

Currently known to support:

* Ubuntu Precise/Trusty
* Debian Woody/Jessie
* Redhat 6/7
* CentOS 6/7

## Development

Feel free to modify, fork or otherwise the module but please keep attribution for the original code to myself:

Copyright 2014, Justice London <jlondon@syrussystems.com>

## Release Notes

There is still some future work to be done:
* Enable .my.cnf support instead of only user/password
* Fix the underlying code for Surrogate to be cleaner/more modular (It works fine though)
* Build tests
