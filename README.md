mojo
====

Git-SVN helper for console


mojo helps to make component-based design easier when using an SVN backend and Git frontend.  Through simple commands, you can run git commands, etc. in multiple repositories at the same time.

There are two types of directories in mojo.  First are "projects" which can be considered as your main repository or set of repositories.  Second, there are "externals" which are repositories that may or may not live in a different directory altogether.  An example:

~/workspace/
  myProject/
    jsProject/
    javaProject/
  javaExternalProject1/
  javaExternalProject2/
  unrelatedProject/
  ...
  
In this example, my main project would my in the myProject directory, but it relys on compenents found in the workspace directory.  jsProject and javaProject would be placed in "projects" and javaExternalProject1 and javaExternalProject2 would be placed in "externals."  Externals are not required, but helpful if you are using component-based design and depending on these projects through something like Maven.
