# Makefile 
#
.SUFFIXES:
.SUFFIXES: .o .f90

include ./user_build_config

OBJS =	lndp_apply_pert.o
	
all:	lndp_apply_pert.exe

.f90.o:
	$(COMPILERF90) -c $(F90FLAGS) $(FREESOURCE) $(NETCDFMOD) $(*).f90

lndp_apply_pert.exe: $(OBJS)
	$(COMPILERF90) -o $(@) $(F90FLAGS) $(FREESOURCE) $(NETCDFMOD) $(OBJS) $(NETCDFLIB)

clean:
	rm -f *.o *.mod *.exe


#
# Dependencies:
#
