mojo
====

What is mojo?
-------------

mojo is a Git-SVN helper for console.  It helps to make component-based design easier when using an SVN backend and Git frontend.  Through simple commands, you can run git commands, etc. in multiple repositories at the same time.

There are two types of directories in mojo.  First are "projects" which can be considered as your main repository or set of repositories.  Second, there are "externals" which are repositories that may or may not live in a different directory altogether.  An example:

* ~/workspace/
  * myProject/
    * __jsProject/__
    * __javaProject/__
  * _javaExternalProject1/_
  * _javaExternalProject2/_
  * unrelatedProject/
  * ...
  
In this example, my main project would be in the myProject directory, but it relies on compenents found in the workspace directory.  __jsProject__ and __javaProject__ would be placed in "projects" and _javaExternalProject1_ and _javaExternalProject2_ would be placed in "externals."  Externals are not required, but helpful if you are using component-based design and depending on these projects through something like Maven.

Installing mojo
---------------

The easiest way to install mojo is to put a copy or link to mojo in the /home/bin directory.  Then make sure that /home/bin is in your PATH. 

> export PATH=$PATH:/home/bin

It is reccomended that you remove the suffix (.sh) when installing into the bin directory or symbollic link within the bin directory

> ln -s path/to/mojo.sh mojo

Initializing and Adding Projects and Externals
----------------------------------------------

In the case above, to initialize a mojo directory, simply move to _~/workspace/myProject/_ and use the command
> mojo -i

which will create a .mojo directory that holds all your configurations for your project. To add any number of projects, use _-p_
> mojo -p jsProject

> mojo -p javaProject

To add an external, use _-e_
> mojo -e javaExternalProject1

> mojo -e javaExternalProject2

Now there are multiple projects and multiple externals associated with this mojo directory.  You can see a list of the projects and externals at any time by using _-l_
> mojo -l

Doing something else
--------------------

To run a different command in each directory of both projects and externals, use _-c_ followed by the command in quotes
> mojo -c "ls"

> mojo -c "pwd; ls; git svn rebase;"


Changing configuration values
-----------------------------

Changing configuration values from within mojo is a ways off, but all the configuration values can be found in the .mojo/config file.  

Currently, you can change 3 values:

* DIR : projects directory... it is not recommended to change this value
* EXT : externals directory
* COMMIT : the command to run when doing a commit.  By default, all files are added (git add --all) before this command is run


The default location of externals is set to the same directory as the projects.  This can be changed by ediing the config file.

The other stuff
---------------

For everything else, use 
> mojo

or 

> mojo -h

to see the help page.

