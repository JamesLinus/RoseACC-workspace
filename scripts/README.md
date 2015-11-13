Before Installing RoseACC
=========================

We provide a bash script to setup the developement environment for ROSE.
It will create the file *roseacc-environment.rc* which will create the ROSEACC\_WORKSPACE\_DIR environment variable.

In the *RoseACC-workspace* directory:
```bash
scripts/setup-gcc-boost.sh
```
Then:
```bash
source roseacc-environment.rc
./setup.sh $(pwd)/build\_dir $(pwd)/install\_dir $(pwd)/opt ... # opencl\_inc opencl\_lib sqlite\_inc sqlite\_lib \[parallel\_make=8\]
```

In some case, file 'ltmain.sh' 
cp ./rose/scripts/buildExampleRoseWorkspaceDirectory/config/ltmain.sh .
Might still miss the *yacc* binary (GNU Bison).
