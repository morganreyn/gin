gin
====

What is gin?
-------------

gin is a Git-SVN helper for console.  It helps to make component-based design easier when using an SVN backend and Git frontend.  Through simple commands, you can run git commands, etc. in multiple repositories at the same time.

There are two types of directories in gin.  First are "projects" which can be considered as your main repository or set of repositories.  Second, there are "externals" which are repositories that may or may not live in a different directory altogether.  An example:

* ~/workspace/
  * myProject/
    * __jsProject/__
    * __javaProject/__
  * _javaExternalProject1/_
  * _javaExternalProject2/_
  * unrelatedProject/
  * ...
  
In this example, my main project would be in the myProject directory, but it relies on components found in the workspace directory.  __jsProject__ and __javaProject__ would be placed in "projects" and _javaExternalProject1_ and _javaExternalProject2_ would be placed in "externals."  Externals are not required, but helpful if you are using component-based design and depending on these projects through something like Maven.

Installing gin
---------------

The easiest way to install gin is to put a copy or link to gin in the /home/bin directory.  Then make sure that /home/bin is in your PATH. 

> export PATH=$PATH:/home/bin

It is recommended that you remove the suffix (.sh) when installing into the bin directory or symbolic link within the bin directory

> ln -s path/to/gin.sh gin

Initializing and Adding Projects and Externals
----------------------------------------------

In the case above, to initialize a gin directory, simply move to _~/workspace/myProject/_ and use the command
> gin -i

which will create a .gin directory that holds all your configurations for your project. To add any number of projects, use _-a p<roject>_
> gin -a p jsProject

> gin -a project javaProject

To add an external, use _-a e<xternal>_
> gin -a e javaExternalProject1

> gin -a external javaExternalProject2

Now there are multiple projects and multiple externals associated with this gin directory.  You can see a list of the projects and externals at any time by using _-l_
> gin -l

Doing something else
--------------------

To run a different command in each directory of both projects and externals, use _-c_ followed by the command in quotes
> gin -c "ls"

> gin -c "pwd; ls; git svn rebase;"


Changing configuration values
-----------------------------

Changing configuration values from within gin is a ways off, but all the configuration values can be found in the .gin/config file.  

Currently, you can change 3 values:

* DIR : projects directory... it is not recommended to change this value
* EXT : externals directory
* COMMIT : the command to run when doing a commit.  By default, all files are added (git add --all) before this command is run


The default location of externals is set to the same directory as the projects.  This can be changed by editing the config file.

The other stuff
---------------

For everything else, use 
> gin

or 

> gin -h

to see the help page.

