# Model_sterilizer
Mathematical model of sterilizer of cans.
This model represents the model of a tuna can sterilizer, it contains several components.
- [Physicochemical properties](sources/Propiedades.el)
- [Ports to connect components](sources/Ports.el)
- [Carts generation](sources/Carts.el)
- [Sterilizer](sources/Sterilizer_ext_matrix_POD.el)
- [Steam valve](sources/Valve.el)
- [Sources](sources/Sources.el)
- [Call](sources/Latas_DLL.el) to C external functions

To run the experiment execute Sterilization_unit->par1->exp1
The matrix calculations to perform apply the Proper Orthogonal Decomposition (POD) method has been implemented in an external C function.
This implementation of the model is based on the Matlab models from:

Pitarch, J. L., Vilas, C., de Prada, C., Palacín, C. G., & Alonso, A. A. (2021). _Optimal operation of thermal processing of canned tuna under product variability_. Journal of Food Engineering, 304, 110594. https://doi.org/10.1016/J.JFOODENG.2021.110594

Some equations related to the heat transfer coefficient and some physical properties have been developed by Santos Galán Casado and  Daniel Hernández Garrigues From Department of Chemical Engineering, Universidad Politécnica de Madrid

## Workspace importation
You can import a ready-to-use workspace in EcosimPro by downloading the file [Sterilizer.pke](Sterilizer.pke)


## Standalone OPC UA Server
The model can be executed independently via OPC UA Server of the simulation model. You can download the [zip file win64_vcr1.zip](win64_vcr1.zip), uncompress it, and execute '_dos_win64_vrc1.exe_' to run the OPC server.
