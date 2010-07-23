! $Id: ocean_mercury_mod.f,v 1.11 2009/09/01 19:21:18 cdh Exp $
      MODULE OCEAN_MERCURY_MOD
!
!******************************************************************************
!  Module OCEAN_MERCURY_MOD contains variables and routines needed to compute
!  the oceanic flux of mercury.  Original code by Sarah Strode at UWA/Seattle.
!  (sas, bmy, 1/21/05, 4/17/06)
!
!  Module Variables:
!  ============================================================================
!  (1 ) Hg_RST_FILE (CHAR   )  : Name of restart file with ocean tracers
!  (2 ) USE_CHECKS  (LOGICAL)  : Flag for turning on error-checking  
!  (3 ) MAX_RELERR  (REAL*8 )  : Max error for total-tag error check [unitless]
!  (4 ) MAX_ABSERR  (REAL*8 )  : Max abs error for total-tag err chk [unitless]
!  (5 ) MAX_FLXERR  (REAL*8 )  : Max error tol for flux error check  [unitless]
!  (6 ) Hg2aq_tot   (REAL*8 )  : Total Hg2 conc. in the mixed layer  [kg      ]
!  (7 ) DD_Hg2      (REAL*8 )  : Array for Hg(II) dry dep'd to ocean [kg      ]
!  (8 ) Hgaq_tot    (REAL*8 )  : Total Hg conc. in the mixed layer   [kg      ]
!  (9 ) Hg0aq       (REAL*8 )  : Array for ocean mass of Hg(0)       [kg      ]
!  (10) Hg2aq       (REAL*8 )  : Array for ocean mass of Hg(II)      [kg      ]
!  (11) HgPaq       (REAL*8 )  : Array for ocean mass of HgP         [kg      ]
!  (12) dMLD        (REAL*8 )  : Array for Change in ocean MLD       [cm      ]
!  (13) MLD         (REAL*8 )  : Array for instantaneous ocean MLD   [cm      ]
!  (14) MLDav       (REAL*8 )  : Array for monthly mean ocean MLD    [cm      ]
!  (15) newMLD      (REAL*8 )  : Array for next month's ocean MLD    [cm      ]
!  (16) NPP         (REAL*8 )  : Array for mean net primary prod.    [unitless]
!  (17) RAD         (REAL*8 )  : Array for mean solar radiation      [W/m2    ]
!  (18) UPVEL       (REAL*8 )  : Array for ocean upwelling velocity  [m/s     ]
!  (19) WD_Hg2      (REAL*8 )  : Array for Hg(II) wet dep'd to ocean [kg      ]
!  (20) CHL         (REAL*8 )  : Chl surface concentration           [mg(m3   ]
!  (21) CDEEPATL    (REAL*8 )  : Conc. Hg0, Hg2, HgP below MLD-Atl   [pM      ]
!  (22) CDEEP       (REAL*8 )  : Conc. of Hg0, Hg2, HgP below MLD    [pM      ]
!  (23) CDEEPNAT    (REAL*8 )  : Conc. Hg0, Hg2, HgP below MLD-NAtl  [pM      ]
!  (24) CDEEPSAT    (REAL*8 )  : Conc. Hg0, Hg2, HgP below MLD-SAtl  [pM      ]
!  (25) CDEEPANT    (REAL*8 )  : Conc. Hg0, Hg2, HgP below MLD-Ant   [pM      ]
!  (26) CDEEPARC    (REAL*8 )  : Conc. Hg0, Hg2, HgP below MLD-Arc   [pM      ]
!
!
!  Module Routines:
!  ============================================================================
!  (1 ) ADD_Hg2_DD             : Archives Hg2 lost to drydep in DD_HG2
!  (2 ) ADD_Hg2_WD             : Archives Hg2 lost to wetdep in WD_HG2
!  (3 ) OCEAN_MERCURY_FLUX     : Routine to compute flux of oceanic mercury
!  (4 ) OCEAN_MERCURY_READ     : Routine to read MLD, NPP, RADSWG data fields
!  (5 ) GET_MLD_FOR_NEXT_MONTH : Routine to read MLD for the next month
!  (6 ) MLD_ADJUSTMENT         : Adjusts MLD 
!  (7 ) READ_OCEAN_Hg_RESTART  : Reads restart file with ocean Hg tracers
!  (8 ) CHECK_DIMENSIONS       : Checks dims of data blocks from restart file
!  (9 ) CHECK_DATA_BLOCKS      : Checks for missing/multiple data blocks
!  (10) MAKE_OCEAN_Hg_RESTART  : Writes new restart file with ocean Hg tracers
!  (11) CHECK_ATMOS_MERCURY    : Checks mass of total & tagged atm Hg0 & Hg2 
!  (12) CHECK_OCEAN_MERCURY    : Checks mass of total & tagged oc Hg0 & Hg2
!  (13) CHECK_OCEAN_FLUXES     : Checks mass of total & tagged DD & WD fluxes
!  (14) INIT_OCEAN_MERCURY     : Allocates and zeroes all module variables
!  (15) CLEANUP_OCEAN_MERCURY  : Deallocates all module variables
!
!  GEOS-CHEM modules referenced by ocean_mercury_mod.f
!  ============================================================================
!  (1 ) bpch2_mod.f            : Module w/ routines for binary pch file I/O
!  (2 ) dao_mod.f              : Module w/ arrays for DAO met fields
!  (3 ) diag03_mod.f           : Module w/ ND03 diagnostic arrays 
!  (2 ) file_mod.f             : Module w/ file unit numbers and error checks
!  (9 ) grid_mod.f             : Module w/ horizontal grid information
!  (10) logical_mod.f          : Module w/ GEOS-CHEM logical switches
!  (11) pressure_mod.f         : Module w/ routines to compute P(I,J,L)
!  (12) time_mod.f             : Module w/ routines to compute date & time
!  (13) tracer_mod.f           : Module w/ GEOS-CHEM tracer array STT etc.
!  (14) tracerid_mod.f         : Module w/ pointers to tracers & emissions
!  (15) transfer_mod.f         : Module w/ routines to cast & resize arrays
!
!  References:
!  ============================================================================
!  (1 ) Xu et al (1999). Formulation of bi-directional atmosphere-surface
!        exchanges of elemental mercury.  Atmospheric Environment 
!        33, 4345-4355.
!  (2 ) Nightingale et al (2000).  In situ evaluation of air-sea gas exchange
!        parameterizations using novel conservative and volatile tracers.  
!        Global Biogeochemical Cycles, 14, 373-387.
!  (3 ) Lin and Tau (2003).  A numerical modelling study on regional mercury 
!        budget for eastern North America.  Atmos. Chem. Phys. Discuss., 
!        3, 983-1015.  And other references therein.
!  (4 ) Poissant et al (2000).  Mercury water-air exchange over the upper St.
!        Lawrence River and Lake Ontario.  Environ. Sci. Technol., 34, 
!        3069-3078. And other references therein.
!  (5 ) Wangberg et al. (2001).  Estimates of air-sea exchange of mercury in 
!        the Baltic Sea.  Atmospheric Environment 35, 5477-5484.
!  (6 ) Clever, Johnson and Derrick (1985).  The Solubility of Mercury and some
!        sparingly soluble mercury salts in water and aqueous electrolyte
!        solutions.  J. Phys. Chem. Ref. Data, Vol. 14, No. 3, 1985.
!
!  Nomenclature: 
!  ============================================================================
!  (1 ) Hg(0)  a.k.a. Hg0 : Elemental   mercury
!  (2 ) Hg(II) a.k.a. Hg2 : Divalent    mercury
!  (3 ) HgP               : Particulate mercury
!
!  NOTES:
!  (1 ) Modified ocean flux w/ Sarah's new Ks value (sas, bmy, 2/24/05)
!  (2 ) Now get HALFPOLAR for GCAP or GEOS grids (bmy, 6/28/05)
!  (3 ) Now can read data for both GCAP or GEOS grids (bmy, 8/16/05)
!  (4 ) Include updates from S. Strode and C. Holmes (cdh, sas, bmy, 4/6/06)
!  (5 ) Change HgC (colloidal) to HgP (particulate) or HgPaq. (ccc, 7/20/10)
!******************************************************************************
!
      IMPLICIT NONE

      !=================================================================
      ! MODULE PRIVATE DECLARATIONS -- keep certain internal variables 
      ! and routines from being seen outside "ocean_mercury_mod.f"
      !=================================================================

      ! Make everything PRIVATE ...
      PRIVATE

      ! ... except these routines
!      PUBLIC :: ADD_Hg2_DD
!      PUBLIC :: ADD_Hg2_WD
!      PUBLIC :: ADD_HgP_DD
!      PUBLIC :: ADD_HgP_WD
      PUBLIC :: INIT_OCEAN_MERCURY
      PUBLIC :: CLEANUP_OCEAN_MERCURY
      PUBLIC :: OCEAN_MERCURY_FLUX
      PUBLIC :: READ_OCEAN_Hg_RESTART
      PUBLIC :: MAKE_OCEAN_Hg_RESTART
!      PUBLIC :: RESET_HG_DEP_ARRAYS
     
!      PUBLIC :: IS_LAND_FIX      !cdh
!      PUBLIC :: IS_WATER_FIX     !cdh
!      PUBLIC :: IS_ICE_FIX       !cdh
!      PUBLIC :: DD_HG2, DD_HGP, WD_HG2, WD_HGP
!      PUBLIC :: SNOW_HG ! CDH snowpack
      PUBLIC :: LDYNSEASALT, LGCAPEMIS, LPOLARBR, LBRCHEM, LBROCHEM
!      PUBLIC :: LRED_JNO2,   LGEOSLWC,  LHGSNOW
      PUBLIC :: LRED_JNO2,   LGEOSLWC
      PUBLIC :: LHg2HalfAerosol,        LHg_WETDasHNO3
      PUBLIC :: STRAT_BR_FACTOR,        LAnthroHgOnly
      PUBLIC :: LOHO3CHEM,              LnoUSAemis
         
      !=================================================================
      ! MODULE VARIABLES
      !=================================================================

      ! Scalars
      LOGICAL              :: USE_CHECKS
      CHARACTER(LEN=255)   :: Hg_RST_FILE

      ! Parameters
      REAL*4,  PARAMETER   :: MAX_RELERR = 5.0d-2
      REAL*4,  PARAMETER   :: MAX_ABSERR = 5.0d-3
      REAL*4,  PARAMETER   :: MAX_FLXERR = 5.0d-1 

      REAL*8   :: CDEEP(3)  
      REAL*8   :: CDEEPATL(3)
      REAL*8   :: CDEEPNAT(3)
      REAL*8   :: CDEEPSAT(3)
      REAL*8   :: CDEEPANT(3)
      REAL*8   :: CDEEPARC(3)
      REAL*8   :: CDEEPNPA(3)

      ! Arrays
!      REAL*8,  ALLOCATABLE :: DD_Hg2(:,:,:)
!      REAL*8,  ALLOCATABLE :: DD_HgP(:,:,:)
       
      REAL*8,  ALLOCATABLE :: dMLD(:,:)
      REAL*8,  ALLOCATABLE :: Hg0aq(:,:,:)
      REAL*8,  ALLOCATABLE :: Hg2aq(:,:,:)
!      REAL*8,  ALLOCATABLE :: HgC(:,:)
      REAL*8,  ALLOCATABLE :: HgPaq(:,:)
      REAL*8,  ALLOCATABLE :: MLD(:,:)
      REAL*8,  ALLOCATABLE :: MLDav(:,:)
      REAL*8,  ALLOCATABLE :: newMLD(:,:)
      REAL*8,  ALLOCATABLE :: NPP(:,:)
      REAL*8,  ALLOCATABLE :: RAD(:,:)
      REAL*8,  ALLOCATABLE :: UPVEL(:,:)
!      REAL*8,  ALLOCATABLE :: WD_Hg2(:,:,:)
!      REAL*8,  ALLOCATABLE :: WD_HgP(:,:,:)
!      REAL*8,  ALLOCATABLE :: SNOW_HG(:,:,:) !CDH Hg stored in snow+ice
      REAL*8,  ALLOCATABLE :: CHL(:,:)                              

      ! Logical switches for the mercury simulation, all of which are 
      ! set in INIT_MERCURY (cdh, 9/1/09)
      LOGICAL   :: LDYNSEASALT, LGCAPEMIS, LPOLARBR, LBRCHEM, LBROCHEM
!      LOGICAL   :: LRED_JNO2,   LGEOSLWC,  LHGSNOW
      LOGICAL   :: LRED_JNO2,   LGEOSLWC
      LOGICAL   :: LHg2HalfAerosol,        LHg_WETDasHNO3
      LOGICAL   :: LAnthroHgOnly,          LOHO3CHEM
      LOGICAL   :: LnoUSAemis
      REAL*8    :: STRAT_BR_FACTOR

      ! CDH Set this TRUE to use corrected area-flux relationship
      ! Set this to FALSE to use original Strode et al. (2007) model
      LOGICAL, PARAMETER :: LOCEANFIX=.TRUE. 
      ! CDH average ocean area per grid box: 1.67d11 m2/box
      ! used when eliminating AREA * FRAC_O
      REAL*8, PARAMETER :: FUDGE=1.67D11

      !=================================================================
      ! MODULE ROUTINES -- follow below the "CONTAINS" statement
      !=================================================================
      CONTAINS

!-------------------------------------------------------------------------
c$$$
c$$$      SUBROUTINE ADD_Hg2_DD( I, J, N, DRY_Hg2)
c$$$!
c$$$!******************************************************************************
c$$$!  Subroutine ADD_Hg2_WD computes the amount of Hg(II) dry deposited 
c$$$!  out of the atmosphere into the column array DD_Hg2. 
c$$$!  (sas, cdh, bmy, 1/19/05, 3/28/06)
c$$$! 
c$$$!  Arguments as Input:
c$$$!  ============================================================================
c$$$!  (1 ) I       (INTEGER) : GEOS-CHEM longitude index
c$$$!  (2 ) J       (INTEGER) : GEOS-CHEM latitude  index
c$$$!  (3 ) N       (INTEGER) : GEOS-CHEM tracer    index
c$$$!  (4 ) DRY_Hg2 (REAL*8 ) : Hg(II) dry deposited out of the atmosphere [kg]
c$$$!
c$$$!  NOTES:
c$$$!  (1 ) DD_Hg2 is now a 3-D array.  Also pass N via the argument list. Now 
c$$$!        call GET_Hg2_CAT to return the Hg category #. (cdh, bmy, 3/28/06)
c$$$!******************************************************************************
c$$$!
c$$$      ! References to F90 modules
c$$$      USE LOGICAL_MOD,  ONLY : LDYNOCEAN
c$$$      USE TRACERID_MOD, ONLY : GET_Hg2_CAT
c$$$
c$$$      ! Arguments as input
c$$$      INTEGER, INTENT(IN)   :: I, J, N
c$$$      REAL*8,  INTENT(IN)   :: DRY_Hg2
c$$$      
c$$$      ! Local variables
c$$$      INTEGER               :: NN
c$$$      
c$$$      !=================================================================
c$$$      ! ADD_Hg2_DD begins here!
c$$$      !=================================================================
c$$$
c$$$      ! Get the index for DD_Hg2 based on the tracer number
c$$$      NN = GET_Hg2_CAT( N )
c$$$
c$$$      ! Store dry deposited Hg(II) into DD_Hg2 array
c$$$      IF ( NN > 0 ) THEN
c$$$         DD_Hg2(I,J,NN) = DD_Hg2(I,J,NN) + DRY_Hg2
c$$$        
c$$$      ENDIF
c$$$      
c$$$     
c$$$      ! Return to calling program
c$$$      END SUBROUTINE ADD_Hg2_DD
c$$$
c$$$!---------------------------------------------------------------------------
c$$$
c$$$      SUBROUTINE ADD_Hg2_WD( I, J, N, WET_Hg2 )
c$$$!
c$$$!******************************************************************************
c$$$!  Subroutine ADD_Hg2_WD computes the amount of Hg(II) wet scavenged 
c$$$!  out of the atmosphere into the column array WD_Hg2. 
c$$$!  (sas, cdh, bmy, 1/19/05, 3/28/06)
c$$$! 
c$$$!  Arguments as Input:
c$$$!  ============================================================================
c$$$!  (1 ) I       (INTEGER) : GEOS-CHEM longitude index
c$$$!  (2 ) J       (INTEGER) : GEOS-CHEM latitude  index
c$$$!  (3 ) N       (INTEGER) : GEOS-CHEM tracer    index
c$$$!  (4 ) WET_Hg2 (REAL*8 ) : Hg(II) scavenged out of the atmosphere
c$$$!
c$$$!  NOTES:
c$$$!  (1 ) DD_Hg2 is now a 3-D array.  Also pass N via the argument list. Now 
c$$$!        call GET_Hg2_CAT to return the Hg category #. (cdh, bmy, 3/28/06)
c$$$!******************************************************************************
c$$$!
c$$$      ! References to F90 modules
c$$$      USE TRACERID_MOD, ONLY : GET_Hg2_CAT
c$$$
c$$$      ! Arguments as input
c$$$      INTEGER, INTENT(IN)   :: I, J, N
c$$$      REAL*8,  INTENT(IN)   :: WET_Hg2
c$$$ 
c$$$      ! Local variables
c$$$      INTEGER               :: NN
c$$$
c$$$      !=================================================================
c$$$      ! ADD_Hg2_WD begins here!
c$$$      !=================================================================
c$$$
c$$$      ! Get Hg2 category number
c$$$      NN = GET_Hg2_CAT( N ) 
c$$$     
c$$$      ! Store wet deposited Hg(II) into WD_Hg2 array
c$$$      IF ( NN > 0 ) THEN
c$$$         WD_Hg2(I,J,NN) = WD_Hg2(I,J,NN) + WET_Hg2
c$$$         
c$$$      ENDIF
c$$$
c$$$      ! Return to calling program
c$$$      END SUBROUTINE ADD_Hg2_WD
c$$$
c$$$!!--------------------------------------------------------------------
c$$$      SUBROUTINE ADD_HgP_DD( I, J, N, DRY_HgP )
c$$$!
c$$$!******************************************************************************
c$$$!  Subroutine ADD_Hg2_WD computes the amount of Hg(II) dry deposited 
c$$$!  out of the atmosphere into the column array DD_Hg2. 
c$$$!  (sas, cdh, bmy, 1/19/05, 3/28/06)
c$$$! 
c$$$!  Arguments as Input:
c$$$!  ============================================================================
c$$$!  (1 ) I       (INTEGER) : GEOS-CHEM longitude index
c$$$!  (2 ) J       (INTEGER) : GEOS-CHEM latitude  index
c$$$!  (3 ) N       (INTEGER) : GEOS-CHEM tracer    index
c$$$!  (4 ) DRY_Hg2 (REAL*8 ) : Hg(II) dry deposited out of the atmosphere [kg]
c$$$!
c$$$!  NOTES:
c$$$!  (1 ) DD_Hg2 is now a 3-D array.  Also pass N via the argument list. Now 
c$$$!        call GET_Hg2_CAT to return the Hg category #. (cdh, bmy, 3/28/06)
c$$$!******************************************************************************
c$$$!
c$$$      ! References to F90 modules
c$$$      USE LOGICAL_MOD,  ONLY : LDYNOCEAN
c$$$      USE TRACERID_MOD, ONLY : GET_HgP_CAT
c$$$
c$$$      ! Arguments as input
c$$$      INTEGER, INTENT(IN)   :: I, J, N
c$$$      REAL*8,  INTENT(IN)   :: DRY_HgP
c$$$ 
c$$$      ! Local variables
c$$$      INTEGER               :: NN
c$$$
c$$$      !=================================================================
c$$$      ! ADD_HgP_DD begins here!
c$$$      !=================================================================
c$$$      
c$$$      ! Get the index for DD_Hg2 based on the tracer number
c$$$      NN = GET_HgP_CAT( N )
c$$$
c$$$      ! Store dry deposited Hg(II) into DD_Hg2 array
c$$$      IF ( NN > 0 ) THEN
c$$$         DD_HgP(I,J,NN) = DD_HgP(I,J,NN) + DRY_HgP
c$$$        
c$$$      ENDIF
c$$$
c$$$      ! Return to calling program
c$$$      END SUBROUTINE ADD_HgP_DD
c$$$
c$$$!-----------------------------------------------------------------------
c$$$
c$$$      SUBROUTINE ADD_HgP_WD( I, J, N, WET_HgP )
c$$$!
c$$$!******************************************************************************
c$$$!  Subroutine ADD_Hg2_WD computes the amount of Hg(II) wet scavenged 
c$$$!  out of the atmosphere into the column array WD_Hg2. 
c$$$!  (sas, cdh, bmy, 1/19/05, 3/28/06)
c$$$! 
c$$$!  Arguments as Input:
c$$$!  ============================================================================
c$$$!  (1 ) I       (INTEGER) : GEOS-CHEM longitude index
c$$$!  (2 ) J       (INTEGER) : GEOS-CHEM latitude  index
c$$$!  (3 ) N       (INTEGER) : GEOS-CHEM tracer    index
c$$$!  (4 ) WET_Hg2 (REAL*8 ) : Hg(II) scavenged out of the atmosphere
c$$$!
c$$$!  NOTES:
c$$$!  (1 ) DD_Hg2 is now a 3-D array.  Also pass N via the argument list. Now 
c$$$!        call GET_Hg2_CAT to return the Hg category #. (cdh, bmy, 3/28/06)
c$$$!******************************************************************************
c$$$!
c$$$      ! References to F90 modules
c$$$      USE TRACERID_MOD, ONLY : GET_HgP_CAT
c$$$
c$$$      ! Arguments as input
c$$$      INTEGER, INTENT(IN)   :: I, J, N
c$$$      REAL*8,  INTENT(IN)   :: WET_HgP
c$$$ 
c$$$      ! Local variables
c$$$      INTEGER               :: NN
c$$$
c$$$      !=================================================================
c$$$      ! ADD_Hg2_WD begins here!
c$$$      !=================================================================
c$$$      
c$$$      ! Get Hg2 category number
c$$$      NN = GET_HgP_CAT( N ) 
c$$$
c$$$      ! Store wet deposited Hg(II) into WD_Hg2 array
c$$$      IF ( NN > 0 ) THEN
c$$$         WD_HgP(I,J,NN) = WD_HgP(I,J,NN) + WET_HgP
c$$$        
c$$$      ENDIF
c$$$      
c$$$      ! Return to calling program
c$$$      END SUBROUTINE ADD_HgP_WD
c$$$
c$$$!-----------------------------------------------------------------------------
c$$$
c$$$      SUBROUTINE RESET_HG_DEP_ARRAYS
c$$$!
c$$$!******************************************************************************
c$$$!  Subroutine RESET_HG_DEP_ARRAYS resets the wet and dry deposition arrays for
c$$$!  Hg(II) and Hg(p) to zero. This allows us to call OCEAN_MERCURY_FLUX and
c$$$!  LAND_MERCURY_FLUX in any order in MERCURY_MOD. (cdh, 9/2/08)
c$$$!
c$$$!  NOTES:
c$$$!  (1 ) 
c$$$!******************************************************************************
c$$$
c$$$         ! Reset deposition arrays.
c$$$         DD_Hg2 = 0d0
c$$$         WD_Hg2 = 0d0
c$$$         DD_HgP = 0d0
c$$$         WD_HgP = 0d0
c$$$
c$$$      END SUBROUTINE RESET_HG_DEP_ARRAYS
c$$$
!-----------------------------------------------------------------------------

      SUBROUTINE OCEAN_MERCURY_FLUX( FLUX )
!
!******************************************************************************
!  Subroutine OCEAN_MERCURY_FLUX calculates emissions of Hg(0) from 
!  the ocean in [kg/s].  (sas, bmy, 1/19/05, 4/17/06)
!
!  NOTE: The emitted flux may be negative when ocean conc. is very low. 
!
!  ALSO NOTE: The ocean flux was tuned with GEOS-4 4x5 met fields.  We also
!  now account for the smaller grid size if using GEOS-4 2x25 met fields.
!    
!  Arguments as Output
!  ============================================================================
!  (1 ) FLUX (REAL*8) : Flux of Hg(0) from the ocean [kg/s]
!_____________________________________________________________________________
!
!  GENERAL SOLUTION - OXIDATION, REDUCTION, SINKING, EVASION, UPWELLING
!
!  dHg0/dt  = Hg0(upw) + Hg0(ent) + Hg0(oa) -k_ox
!             + k_red * Frac_Hg2 * Reducible * HgII
!
!  dHgII/dt = HgII(dep) + HgII(up) + HgII(ent) - HgII(sink) +
!             k_ox * Hg0-k_red * Frac_Hg2 * Reducible * HgII
!____________________________________________________________________________
!
! Hg(tot)aq REDUCTION RATE CONSTANTS
!
! Hg(tot)aq reduction is split into biological and radiative reduction
!  (1.1 added to NPP for abiotic particles)
!
!   k_red     = k_red_bio + k_red_rad
!   k_red_rad = k_radbase * RADz     = ( s-1 W-1 m2 ) * ( W m-2 )
!   k_red_bio = k_biobse * NPP * 1.1 = ( s-1 mgC-1 d ) * ( mgC m-2 d-1 )
!
!
! Hg(0)aq OXIDATION RATE CONSTANTS
!
!   k_ox      = k_oxbase * RADz + k_dark
!
! k_dark is a constant dark oxidation component
!
! RADz is the integrated ligth attenuation based on Beer-Lamberts law 
! (Schwarzenbach et al. 1993)
!
!    RADz = (1/(x1-x2))(RAD/EC)(1-e**-EC * x2)
! 
! x1  = surface depth (=0) (m)
! x2  = depth of mixed layer (m)
! EC  = extinction coefficient (m-1)
! RAD = incomming radiation from GEOS5
!
! Extinction coefficient
! EC = ECwater + ECdoc * Cdoc (NPP/NPPavg) + ECchla * CHL/1000
!
! ECwater = 0.0145 m-1
! ECdoc   = 0.654 m-1
! Cdoc    = 1.5 mgL-1
! ECchla  = 31 m-1
! CHL     = amount dependent on inputfile (mg/m3) but we need 
!           mg/L so divide CHL by 1000
!____________________________________________________________________________
!
! TOTAL ORGANIC CARBON AND SUSPENDED PARTICULATE MATTER (TOTAL BIOMASS)
!
! Hg(II) - Hg(P) partitioning coefficient
!
!   Fraction of Hg2 = Frac_Hg2 =  1 / ( 1 + kd_part * SPM )
!
! Kd_part is based on Mason et al. 1998 and Mason & Fitzgerald 1993. (L/kg)
! SPM is converted to kg/L by 10E-9
!
! SPM is Suspended particulate matter (kg/L)
!
!   SPM = ( OC_tot * 10 / MLD ) * 1.1
!
! Total biomas is a proxy for SPM (mg/m3) used in Hg(II)
! partitioning. Calculated by multiplying the standing 
! stock of organic carbon (OC_tot) with 10 (exp Bundy 2004)
! 1.1 is to include abiotic particles
!
! OC_tot is the standing stock of organic carbon (mgC/m�)
!
!   OC_tot = C_tot * 80
!
! Standing stock is calculated based on C:Chl ratio of 80 (wetzel et al 2006)
!
! C_tot is the integrated pigment content in euphotic layer (mg/m2)
!
! The parameters for calculating integrated Chl is based on a
! model by Uitz et al (2006).
!
! CHL   = average Chl a conc. detected by Modis (mg/m3)
! Zm    = mixed layer depth (m)
! Ze    = euphotic depth (PAR 1% of surface value (m)
!
! C_tot differs dependent on the water being stratified 
! or well-mixed.
!___________________________________________________________________________
!
! GAS EXCHANGE
!
! Net flux from the ocean is given by the equation:
!  
!   F = Kw * ( CHg0_aq - CHg0_atm / H )    (Lis & Slanter 1974)
!
! Kw is the mass transfer coefficient (cm/h)
!   There are different possibilities for calculating Kw. The default is:
!
!   Kw = 0.25 * u^2 / SQRT ( Sc / ScCO2 )  (Nightingale et al. 2000)
!
! u^2 is the square of the wind speed (10m above ground) (m�/s�)
!
! Sc is the Schmidt # for Hg [unitless]                             
!    (ref: Poissant et al 2000; Wilke and Chang 1995)
!    to correct for seawater D0 is decreased by 6% as suggested
!    by Wanninkhof (1992)
!
!   Sc = v/D = (0.017 * exp(-0.025T))/D = kinematic viscosity/diffusivity
!
! Diffusivity is calculated by:
!   D = (7.4*10D-8 scrt(2.26 * Mw) * TK) / (vi * N**0.6)
!
!   vi = viscocity of water
!   N  = molal volumen of mercury = 14.18
!
! Viscocity is taken from Loux (2001)
!
! H is the diemensionless Henrys coefficient for elemental mercury
!
!   H = exp (-2404.3/T - 6.92) where T is sea temp in K (Andersson et al. 2008)  
!___________________________________________________________________________
!
! PARTICLE SINKING
!
! (from Sunderland & Mason 2007)
!
! JorgC_kg = 0.1 (NPP**1.77) (MLD**-0.74)
!____________________________________________________________________________
!
!  NOTES:
!  (1 ) Change Ks to make ocean flux for 2001 = 2.03e6 kg/year.
!        (sas, bmy, 2/24/05)
!  (2 ) Rewritten to include Sarah Strode's latest ocean Hg model code.
!        Also now accounts for 2x25 grid. (sas, cdh, bmy, 4/6/06)
!  (3 ) Ocean parameterizations are rewritten entirely to account for actual
!        processes in the ocean. Different subsurface conc. are included
!        (anls, 20/10/09)
!******************************************************************************
!
      ! References to F90 modules
      USE DAO_MOD,       ONLY : AIRVOL, ALBD, TSKIN, RADSWG              
      USE DIAG03_MOD,    ONLY : AD03, ND03
      USE DIRECTORY_MOD, ONLY : DATA_DIR
      USE GRID_MOD,      ONLY : GET_AREA_M2, GET_XMID, GET_YMID 
      USE LOGICAL_MOD,   ONLY : LSPLIT
      USE TIME_MOD,      ONLY : GET_TS_EMIS,     GET_MONTH 
      USE TIME_MOD,      ONLY : ITS_A_NEW_MONTH, ITS_MIDMONTH
      USE TRACER_MOD,    ONLY : STT,             TRACER_MW_KG
      USE TRACERID_MOD,  ONLY : ID_Hg_tot,       ID_Hg_oc
      USE TRACERID_MOD,  ONLY : ID_Hg0,          N_Hg_CATS
      USE TRANSFER_MOD,  ONLY : TRANSFER_2D
      USE DEPO_MERCURY_MOD, ONLY: DD_Hg2, WD_Hg2, DD_HgP, WD_HgP
 

#     include "CMN_SIZE"      ! Size parameters
#     include "CMN_DEP"       ! FRCLND

      ! Arguments 
      REAL*8,  INTENT(OUT)  :: FLUX(IIPAR,JJPAR,N_Hg_CATS)


      ! Local variables
      LOGICAL, SAVE         :: FIRST = .TRUE.
      CHARACTER(LEN=255)    :: FILENAME
      INTEGER               :: I,         J,        NN, C
      INTEGER               :: N,         N_tot_oc
      INTEGER               :: NEXTMONTH, THISMONTH

      REAL*8                :: A_M2,     DTSRCE,   MLDCM
      REAL*8                :: CHg0aq,   CHg0,     vi,       JorgC_kg           
      REAL*8                :: TC,       TK,       Kw
      REAL*8                :: Sc,       ScCO2,    USQ,      MHg
!      REAL*8                :: Hg2_RED,  Hg2_GONE, Hg2_CONV, HgC_SUNK
      REAL*8                :: Hg2_RED,  Hg2_GONE, Hg2_CONV, HgPaq_SUNK
      REAL*8                :: FRAC_L,   FRAC_O,   H,        TOTDEP
      REAL*8                :: oldMLD,   XTAU,     TOTDEPall                   
      REAL*8                :: FUP(IIPAR,JJPAR,N_Hg_CATS)
      REAL*8                :: FDOWN(IIPAR,JJPAR,N_Hg_CATS)
      REAL*8                :: X,        Y,        D                           
      REAL*8                :: NPP_tot,  A_ocean,  NPP_avg,  RADz        
      REAL*8                :: EC         
      REAL*8                :: k_red,    k_red_rad,  k_red_bio          
      REAL*8                :: k_ox    
      REAL*8                :: SPM,      Frac_Hg2, OC_tot_kg          
      REAL*8                :: Hgaq_tot, Hg2aq_tot                      
      REAL*8                :: C_tot,    Ze,       OC_tot,   Hg0_OX     

      ! Parameters
      REAL*8, PARAMETER     :: EC_w      = 0.0145d0       
      REAL*8, PARAMETER     :: EC_doc    = 0.654d0
      REAL*8, PARAMETER     :: C_doc     = 1.5d0 
      REAL*8, PARAMETER     :: k_radbase = 1.73d-6                     
      REAL*8, PARAMETER     :: k_biobase = 4.1d-10    
      REAL*8, PARAMETER     :: k_oxbase  = 6.64d-6 
      REAL*8, PARAMETER     :: Kd_part   = 10**(5.5)    
      REAL*8, PARAMETER     :: k_ox_dark = 1d-7  
      REAL*8, PARAMETER     :: ECchla    = 31d0     

      ! Conversion factor from [cm/h * ng/L] --> [kg/m2/s]
      REAL*8,  PARAMETER    :: TO_KGM2S = 1.0D-11 / 3600D0 

      ! Small numbers to avoid dividing by zero
      REAL*8,  PARAMETER   :: SMALLNUM   = 1D-32
      REAL*8,  PARAMETER   :: NPPMINNUM   = 5D-2       
      REAL*8,  PARAMETER   :: CHLMINNUM   = 1D-1       

      ! External functions
      REAL*8,  EXTERNAL     :: SFCWINDSQR 
     
      !=================================================================
      ! OCEAN_MERCURY_FLUX begins here!
      !=================================================================

      ! Loop limit for use below
      IF ( LSPLIT ) THEN
         N_tot_oc = 2
      ELSE
         N_tot_oc = 1
      ENDIF

      ! Molecular weight of Hg (applicable to all tagged tracers)
      MHg = TRACER_MW_KG(ID_Hg_tot)

      !-----------------------------------------------
      ! Check tagged & total sums (if necessary)
      !-----------------------------------------------
      IF ( USE_CHECKS .and. LSPLIT ) THEN
         CALL CHECK_ATMOS_MERCURY( 'start of OCEAN_MERCURY_FLUX' )
         CALL CHECK_OCEAN_MERCURY( 'start of OCEAN_MERCURY_FLUX' )
         CALL CHECK_OCEAN_FLUXES ( 'start of OCEAN_MERCURY_FLUX' )
      ENDIF

      !-----------------------------------------------
      ! Read monthly NPP, RADSW, MLD, UPVEL data
      !-----------------------------------------------
      IF ( ITS_A_NEW_MONTH() ) THEN

         ! Get current month
         THISMONTH = GET_MONTH()

         ! Get monthly MLD, NPP, CHL etc.                         
         CALL OCEAN_MERCURY_READ( THISMONTH )

      ENDIF    
     
      !-----------------------------------------------
      ! MLD and entrainment change in middle of month
      !-----------------------------------------------
      IF ( ITS_MIDMONTH() ) THEN

         ! Get current month
         THISMONTH = GET_MONTH()

         ! Read next month's MLD
         CALL GET_MLD_FOR_NEXT_MONTH( THISMONTH )
         
      ENDIF


      ! Emission timestep [s]
      DTSRCE = GET_TS_EMIS() * 60d0

      !----------------------------------------------------------------
      ! Calculate total mean NPP (mg/m2/day) for later                                                  
      !----------------------------------------------------------------                                     
      ! Initialize values
      NPP_tot = 0d0
      A_ocean = 0d0

      DO J = 1, JJPAR
      DO I = 1, IIPAR

         ! Grid box surface area [m2]
         A_M2 = GET_AREA_M2( J )

         NPP_tot = NPP_tot+ NPP(I,J) * A_M2 * ( 1d0 - FRCLND(I,J))

         A_ocean = A_ocean + A_M2 * ( 1 - FRCLND(I,J) ) 

      ENDDO
      ENDDO

      NPP_avg = NPP_tot / A_ocean


      ! Loop over latitudes   
!!$OMP PARALLEL DO
!!$OMP+DEFAULT( SHARED )
!!$OMP+PRIVATE( I,   vi,   A_M2,   HgC_A,   Hg2_RED,   Hgaq_tot   )
!!$OMP+PRIVATE( J,   NN,   k_ox,   OC_tot,  Hg2aq_A,   Hg2_CONV   )
!!$OMP+PRIVATE( N,   TK,   CHg0,   FRAC_L,  Hg2aq_B,   k_red_bio  )
!!$OMP+PRIVATE( C,   TC,   RADz,   Hg0_OX,  HgC_sum,   k_red_rad  )
!!$OMP+PRIVATE( D,   EC,   k_red,  OLDMLD,  Hg0aq_A,   TOTDEPall  )
!!$OMP+PRIVATE( Y,   Ze,   ScCO2,  FRAC_O,  Frac_Hg2,  Hg2aq_tot  )
!!$OMP+PRIVATE( H,   Kw,   MLDCM,  TOTDEP,  HgC_SUNK,  OC_tot_kg  )
!!$OMP+PRIVATE( X,   SPM,  HgC_B,  CHg0aq,  Hg2_GONE,  Hg0aq_SUM  )
!!$OMP+PRIVATE( Sc,  Usq,  C_tot,  Hg0aq_B, JorgC_kg,  Hg2aq_SUM  )
!!$OMP+PRIVATE( Hg2_RED_RAD                                       )
!!$OMP+SCHEDULE( DYNAMIC )

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,   vi,   A_M2,    Hg2_RED, Hgaq_tot   )
!$OMP+PRIVATE( J,   NN,   k_ox,    OC_tot,  Hg2_CONV   )
!$OMP+PRIVATE( N,   TK,   CHg0,    FRAC_L,  k_red_bio  )
!$OMP+PRIVATE( C,   TC,   RADz,    Hg0_OX,  HgPaq_sum,  k_red_rad  )
!$OMP+PRIVATE( D,   EC,   k_red,   OLDMLD,  TOTDEPall  )
!$OMP+PRIVATE( Y,   Ze,   ScCO2,   FRAC_O,  Frac_Hg2,   Hg2aq_tot  )
!$OMP+PRIVATE( H,   Kw,   MLDCM,   TOTDEP,  HgPaq_SUNK, OC_tot_kg  )
!$OMP+PRIVATE( X,   SPM,  CHg0aq,  Hg2_GONE,   )
!$OMP+PRIVATE( Sc,  Usq,  C_tot,   JorgC_kg,   )
!$OMP+SCHEDULE( DYNAMIC )

      DO J = 1, JJPAR

         ! Grid box surface area [m2]
         A_M2 = GET_AREA_M2( J )

      ! Loop over longitudes
      DO I = 1, IIPAR

         ! Initialize values
         Kw         = 0d0
!         HgC_SUNK   = 0d0
         HgPaq_SUNK   = 0d0
         Hg2_CONV   = 0d0
         TK         = 0d0
         TC         = 0d0 
         JorgC_kg   = 0d0                              
         EC         = 0d0
         RADz       = 0d0
         k_red      = 0d0
         k_red_rad  = 0d0
         k_red_bio  = 0d0
         SPM        = 0d0
         Frac_Hg2   = 0d0   
         Hg2aq_tot  = 0d0
         Hgaq_tot   = 0d0
         Hg2_RED    = 0d0
         C_tot      = 0d0
         Ze         = 0d0
         OC_tot     = 0d0
         OC_tot_kg  = 0d0 
         Hg0_OX     = 0d0
         D          = 0d0
         TOTDEPall  = 0d0
         k_ox       = 0d0

         OLDMLD     = MLDav(I,J)
         MLDav(I,J) = MLDav(I,J) + dMLD(I,J) * DTSRCE
         MLDcm      = MLDav(I,J)

         ! Get fractions of land and ocean in the grid box [unitless]
         FRAC_L     = FRCLND(I,J)
         FRAC_O     = 1d0 - FRAC_L

         ! Change ocean mass due to mixed layer depth change
         ! Keep before next IF so that we adjust mass in ice-covered boxes 
         CALL MLD_ADJUSTMENT( I, J, OLDMLD*1d-2, MLDcm*1d-2 )


         !===========================================================
         ! Make sure we are in an ocean box
         !===========================================================
         IF ( ( ALBD(I,J) <= 0.4d0 ) .and. 
     &        ( FRAC_L    <  0.8d0 ) .and.
     &        ( MLDCM     > 0.99d0 )      ) THEN


            !===========================================================
            ! Reduction and oxidation coefficients
            !===========================================================    
            ! Avoid having NPP or CHL to be zero
            NPP(I,J) = MAX ( NPP(I,J) , NPPMINNUM )  

            CHL(I,J)    = MAX ( CHL(I,J) , CHLMINNUM )                       

            ! Light attenuation (RADz) is calculated
            EC     = (EC_w + ( EC_doc * C_doc * ( NPP(I,J) / NPP_avg ) ) 
     &               + ( ECchla * CHL(I,J) / 1000 ) )             

            RADz   = ( 1 / ( MLDcm * 1d-2 )) * ( RADSWG(I,J) / EC )    
     &               * ( 1 - EXP( -EC * ( MLDcm * 1d-2) ) )

            !--------------------------------------------------------
            ! Hg(tot)aq reduction rate constants
            !--------------------------------------------------------

            k_red_rad   = ( k_radbase * RADz )    

            k_red_bio   = ( ( k_biobase * NPP(I,J) ) * 1.1 )   !NPP is increased by 0.1

            k_red       = k_red_rad + k_red_bio


            !-------------------------------------------------------
            ! Hg(0)aq oxidation rate constants
            !------------------------------------------------------
            
            k_ox        = ( k_ox_dark + ( k_oxbase * RADz ) )  


            !=========================================================
            ! Partitioning and organic carbon
            !========================================================= 

            ! Calculation of C_tot for stratified waters
            IF (CHL(I,J) <= 1.0) THEN
               C_tot    = 36.1d0 * CHL(I,J)**0.357d0
            ELSE
               C_tot    = 37.7d0 * CHL(I,J)**0.615d0
            ENDIF

            ! Calculation of the euphotic depth
            IF (C_tot > 13.65) THEN
               Ze       = 912.0d0 * C_tot**(-0.839d0)
            ELSE
               Ze       = 426.3d0 * C_tot**(-0.547d0)
            ENDIF

            ! Recalculation of C_tot if water is shown to be well-mixed
            IF ((Ze/(MLDcm*1d-2)) < 1) THEN
               C_tot    = 42.1d0 * CHL(I,J)**0.538d0
            ENDIF

            !--------------------------------------------------------------
            ! Standing stock of organic carbon and total biomass
            !--------------------------------------------------------------
            ! Calculated based on C:Chl ratio of 80 (wetzel et al 2006)
            ! Stodk of organic carbon is in mgC/m2
            ! Then converting to OC_tot_kg in kg/grid

            OC_tot      = C_tot * 80.0d0

            OC_tot_kg   = OC_tot * 1d-6 * A_M2 * FRAC_O


            ! Total biomas is a proxy for SPM (mg/m3) used in Hg(II)
            ! partitioning. Calculated by multiplying the standing 
            ! stock of organic carbon with 10 (exp Bundy 2004)

            SPM = ( OC_tot * 10.0d0 / ( MLDcm * 1d-2 ) ) * 1.1                   

            !-------------------------------------------------------------- 
            ! Hg(II) - Hg(P) partitioning coefficient
            !--------------------------------------------------------------
            ! Kd_part is based on Mason et al. 1998 and Mason &
            ! Fitzgerald 1993. (L/kg)
            ! SPM is converted to kg/L by 10E-9

            ! SPM = Suspended particulate matter (kg/L)

            Frac_Hg2    = 1 / ( 1 + Kd_part * SPM * 1d-9)


            !--------------------------------------------------------------
            ! Sea surface temperature in both [K] and [C]
            !--------------------------------------------------------------
            ! where TSKIN is the temperature (K) at the ground/sea surface
            ! (Use as surrogate for SST, cap at freezing point)

            TK     = MAX( TSKIN(I,J), 273.15d0 )                           

            TC     = TK - 273.15d0

            !==============================================================
            ! Volatilisation of Hg0
            !==============================================================
            
            ! Henry's law constant (gas->liquid) [unitless] [L water/L air]  
            ! (ref: Andersson et al. 2008)

            H      = EXP( ( -2404.3d0 / TK ) + 6.92d0 )

            ! Viscosity as a function of changing temperatures
            ! (ref: Loux 2001)
            ! The paper says the viscosity is given in cP but us really P
            ! and we therefor multiply with 100 to get cP.

            vi    = ( 10**( ( 1301.0d0 / ( 998.333d0 + 8.1855d0 
     &              * ( TC - 20.0d0 )+ 0.00585d0 * (TC - 20.0d0 )**2 ) ) 
     &              - 3.30233d0 ) ) * 100.0d0      

            ! Schmidt # for Hg [unitless]                             
            ! Sc = v/D = kinematic viscosity/diffusivity
            ! (ref: Poissant et al 2000; Wilke and Chang 1995)
            ! to correct for seawater D0 is decreased by 6% as suggested
            ! by Wanninkhof (1992)

            D = 7.4D-8 * sqrt( 2.26 * 18.0 ) * TK /
     &             ( ( 14.8**0.6 ) *vi )

            Sc   = ( 0.017d0 * EXP( -0.025d0 * TC ) ) / D                      
            
            ! Schmidt # of CO2 [unitless] for CO2 in seawater at 20 degrees C
            ! The value is set to a constant based on other ocean studies
            ! (Gardfeld et al. 2003, Rolfhus & Fitzgerald 2004, Mason et al. 2001)

            ! Correction of the Schmidt # with temperature based on Poissant
            ! et al. (2000) (for freshwatersystems).

            ScCO2  = 644.7d0 + TC * ( -6.16d0 + TC * ( 0.11d0 ) ) 

            ! Square of surface (actually 10m) wind speed [m2/s2]

            Usq    = SFCWINDSQR(I,J)

            !------------------------------------------------------
            ! Parameterizations for calculating water side mass trasfer coefficient 
            !------------------------------------------------------
            ! Mass transfer coefficient [cm/h], from Nightingale et al. 2000
            Kw     = ( 0.25d0 * Usq ) / SQRT( Sc / ScCO2 )             

            !-----------------------------------------------------
            ! Additional parameterizations:

            ! Nightinale et al. 2000 for instantanous winds

!            Kw     = ( 0.33d0*SQRT(usq)+0.22d0*Usq) / SQRT( Sc / ScCO2 )    

            ! Lis and Merlivat 1986
            ! Has less emphasis on windspeed as a driver for evasion
            ! Gives a less total evasion than the Nigthingale et al. 2000

!            IF (SQRT(Usq) <= 3.6d0 ) THEN                               
!               Kw = ( 0.17d0 * SQRT(Usq) * ( Sc / ScCO2 )**0.67d0 )
!            ELSE IF (SQRT(Usq) > 3.6d0 .and. SQRT(Usq) <= 13d0 ) THEN
!               Kw = ( ( 2.8d0 * SQRT(Usq))-9.6 ) * ( Sc / ScCO2 )**0.5d0
!            ELSE  
!               Kw = ( ( 5.9d0 * SQRT(Usq))-49.3 ) * ( Sc / ScCO2)**0.5d0
!            ENDIF

            ! Wanninkhof et al (1992)

!            Kw     = ( 0.31d0 * Usq ) / SQRT( Sc / ScCO2 )

            !===========================================================
            ! Particulate sinking                              
            !===========================================================
            ! HgP sinking is based on Sunderland & Mason 2007.
            ! JorgC originally in gC m-2 year-1, which is convereted 
            ! to kgC grid-1 timestep-1
            ! NPP is converted from mgC/m2/d-1 to gC/m2/year-1
            ! JorgC = 0.1 ( ( NPP * 12 )**1.77 ) *  MLD**n * M2 * Frac_O 
            !         * 10^-3 * DTSRCE / ( 365 * 24 * 60 * 60 )

            JorgC_kg  = ( ( 0.1d0 * ((( NPP(I,J) * 365) / 1000 )**1.77 )
     &                * ( ( MLDcm * 1d-2 )**(-0.74d0) ) * A_M2 * FRAC_O 
     &                * 1d-3) / ( 365.0d0 * 24.0d0 * 60.0d0 * 60.0d0 ) )
     &                * DTSRCE                     


            !-----------------------------------------------------------
            ! Physical transport for tracers, Part II:
            ! Upward current transport (Ekman pumping)
            ! Upward mass flux is:
            ! Mass = (Vol upwelling water) * (Conc. below thermocline)
            ! Mass = (VEL * AREA * TIME  ) * (C * Molar Mass )
            !-----------------------------------------------------------
 
            ! Use CDEEPATL to scale deepwater in NAtlantic            

            IF ( UPVEL(I,J) > 0d0 ) THEN
                 
            ! Loop over total Hg (and ocean Hg if necessary)
            DO C = 1, N_tot_oc

               ! Grid-box latitude [degrees]
               Y = GET_YMID( J )
         
               ! Grid box longitude [degrees]
               X = GET_XMID( I )

               ! Get Hg category #
               IF ( C == 1 ) NN = ID_Hg_tot
               IF ( C == 2 ) NN = ID_Hg_oc


               ! Atlantic
               IF ( ( X >= -80.0 .and. X < 25.0 )  .and.
     &              ( Y >= -25.0 .and. Y < 55.0 ) ) THEN    !(anls,100114)

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepatl(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepatl(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepatl(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepatl(3) )
                  ENDIF
 
               !North Pacific (west)  
               ELSE IF ( ( X >= -180.0 .and. X < -80.0 )  .and.
     &                   ( Y >=   30.0 .and. Y <  70.0 ) ) THEN

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(3) )
                  ENDIF

               !North Pacific (east)  
               ELSE IF ( ( X >= 25.0 .and. X < 180.0 )  .and.
     &                   ( Y >= 30.0 .and. Y <  70.0 ) ) THEN

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnpa(3) )
                  ENDIF


               ! North Atlantic
               ELSE IF ( ( X >= -80.0 .and. X < 25.0 )  .and.
     &                   ( Y >=  55.0 .and. Y < 70.0 ) ) THEN

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnat(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnat(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnat(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepnat(3) )
                  ENDIF

               
               ! South Atlantic
               ELSE IF ( ( X >= -80.0 .and. X <  25.0 )  .and.
     &                   ( Y >= -65.0 .and. Y < -25.0 ) ) THEN   !(anls,100114)

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepsat(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepsat(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepsat(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepsat(3) )
                  ENDIF


               ! Antarctic
               ELSE IF ( Y >=  -90.0 .and. Y <  -65.0 ) THEN

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepant(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepant(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepant(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeepant(3) )
                  ENDIF


               ! Arctic
               ELSE IF ( Y >=  70.0 .and. Y <  90.0 ) THEN

                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeeparc(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeeparc(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeeparc(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeeparc(3) )
                  ENDIF
               
               ELSE
                  ! Hg0 (kg)
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeep(1) )

                  ! Hg2 
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) + UPVEL(I,J)
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeep(2) )

                  ! Hg particulate
                  IF ( C == 1 ) THEN
!                     HgC(I,J)   = HgC(I,J) + UPVEL(I,J) 
!     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeep(3) )
                     HgPaq(I,J)   = HgPaq(I,J) + UPVEL(I,J) 
     &                 * ( MHg * A_M2 * FRAC_O * DTSRCE * CDeep(3) )
                  ENDIF
               
               ENDIF

            ENDDO
 
                  
            !----------------------------------------------------------
            ! Physical transport for TOTAL TRACERS, Part III:
            ! Downward current transport (Ekman pumping)
            ! Treated as a deposition velocity
            ! d(Mass)/dt = - VEL * Mass / BoxHeight
            !----------------------------------------------------------
            ELSE  

               ! Loop over all types of tagged tracers
               DO NN = 1, N_Hg_CATS

                  ! Hg0
                  Hg0aq(I,J,NN) = Hg0aq(I,J,NN) 
     &                * ( 1d0 + UPVEL(I,J) * DTSRCE / ( MLDcm * 1d-2 ) ) 
                  
                  ! Hg2
                  Hg2aq(I,J,NN) = Hg2aq(I,J,NN) 
     &                * ( 1d0 + UPVEL(I,J) * DTSRCE / ( MLDcm * 1d-2 ) )
               
                  ! Hg particulate
                  IF ( NN == 1 ) THEN
!                     HgC(I,J)  = HgC(I,J) 
!     &                * ( 1d0 + UPVEL(I,J) * DTSRCE / ( MLDcm * 1d-2 ) )
                     HgPaq(I,J)  = HgPaq(I,J) 
     &                * ( 1d0 + UPVEL(I,J) * DTSRCE / ( MLDcm * 1d-2 ) )
                  ENDIF

               ENDDO

            ENDIF


            !===========================================================
            ! Calculate reduction, conversion, sinking, evasion
            !
            ! (1) Hg2 <-> HgP and HgP sinks
            ! (2) Hg2 <-> Hg0 and Hg0 evades
            !
            ! NOTE: N is the GEOS-CHEM tracer # (for STT)
            !       and NN is the Hg category # (for Hg0aq, Hg2aq, HgP)
            !===========================================================

            ! Loop over all Hg categories
            DO NN = 1, N_Hg_CATS

               ! Reset flux each timestep
               FLUX(I,J,NN)  = 0d0 
               FUP(I,J,NN)   = 0d0
               FDOWN(I,J,NN) = 0d0

                  
               !--------------------------------------------------------
               ! Calculate new Hg(II) mass
               !--------------------------------------------------------

               ! Before 11/3/2009 (cdh, hamos)
               !! Total Hg(II) deposited on ocean surface [kg]
               !TOTDEP = (WD_Hg2(I,J,NN) + DD_Hg2(I,J,NN))*FRAC_O 
               !                 
               ! Total Hg(II) deposited on ocean surface [kg]
               ! Includes gaseous and particulate reactive Hg(II)
               ! plus anthropogenic primary Hg(p) (cdh, hamos 11/3/2009)
               TOTDEPall = (WD_Hg2(I,J,NN) + DD_Hg2(I,J,NN) +
     &                   WD_HgP(I,J,NN) + DD_HgP(I,J,NN) ) 

               TOTDEP        = TOTDEPall * FRAC_O

               ! Add deposited Hg(II) to the Hg(II)tot ocean mass [kg]
!               Hg2aq_tot     = Hg2aq(I,J,NN) + HgC(I,J) + TOTDEP      
               Hg2aq_tot     = Hg2aq(I,J,NN) + HgPaq(I,J) + TOTDEP      

               Hg2aq(I,J,NN) = Hg2aq_tot * Frac_Hg2               


               ! Mass of Hg(II)  -->  Hg(0) 
               ! Only a certain percentage of Hg(II) is considered reducible
               Hg2_RED       = Hg2aq(I,J,NN) * 0.4d0 * k_red * DTSRCE       
               ! Mass of Hg(0) --> Hg(II)
               Hg0_OX        = Hg0aq(I,J,NN) * k_ox * DTSRCE

               ! Amount of Hg(II) that is lost [kg]
               Hg2_GONE      = Hg2_RED - Hg0_OX                        

               ! Cap Hg2_GONE with available Hg2
               IF ( Hg2_GONE > Hg2aq(I,J,NN) ) THEN 
                  Hg2_GONE   = MIN( Hg2_GONE, Hg2aq(I,J,NN) )
               ENDIF

               IF ( (Hg2_GONE * (-1d0)) >  Hg0aq(I,J,NN)) THEN         
                  Hg2_GONE   = (Hg0aq(I,J,NN)*(-1))   
                  !MAX (Hg2_GONE ,(Hg0aq(I,J,NN)*(-1d0)))
               ENDIF

               ! Hg(II) ocean mass after reduction and conversion [kg]
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN) - Hg2_GONE

               !--------------------------------------------------------
               ! Calculate new Hg(P) mass
               !--------------------------------------------------------
               IF ( NN == 1 ) THEN

                  ! HgP ocean mass after conversion
!                  HgC(I,J)   = Hg2aq_tot * ( 1 - Frac_Hg2)
                  HgPaq(I,J)   = Hg2aq_tot * ( 1 - Frac_Hg2)
                     

                  !----------------------------------------------------
                  ! Conversion between OC and Hg                          
                  !----------------------------------------------------
                  ! Hg/C ratio based on HgP(kg) and Stock of organic C(kg)
                  ! HgPaq_sunk funtion of C sunk and HgP/C ratio   
        
!                  HgC_SUNK  = JorgC_kg * ( HgC(I,J) / OC_tot_kg)          
                  HgPaq_SUNK  = JorgC_kg * ( HgPaq(I,J) / OC_tot_kg)          


                  ! HgP ocean mass after sinking [kg]

!                  HgC(I,J)   = HgC(I,J) - HgC_SUNK

!                  HgC(I,J)   = MAX ( HgC(I,J) , 0.0 )                 

                  HgPaq(I,J)   = HgPaq(I,J) - HgPaq_SUNK

                  HgPaq(I,J)   = MAX ( HgPaq(I,J) , 0.0 )                 

                  ! Store carbon sinking [kgC/time]
                  IF ( ND03 > 0 ) THEN
                     AD03(I,J,12) = AD03(I,J,12) + JorgC_kg
                  ENDIF

               ENDIF

               !--------------------------------------------------------
               ! Calculate new Hg(0) mass
               !--------------------------------------------------------

               ! Hg0 tracer number (for STT)
               N             = ID_Hg0(NN)

               ! Add converted Hg(II) and subtract converted Hg(0) mass 
               ! to the ocean mass of Hg(0) [kg]
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN) + Hg2_GONE     

               !--------------------------------------------------------
               ! Calculate oceanic and gas-phase concentration of Hg(0)
               !--------------------------------------------------------
                  
               ! Concentration of Hg(0) in the ocean [ng/L]
               CHg0aq        = ( Hg0aq(I,J,NN) * 1d11   ) /   
     &                         ( A_M2          * FRAC_O ) / MLDcm 
               
               ! Gas phase Hg(0) concentration: convert [kg] -> [ng/L]
               CHg0          = STT(I,J,1,N) * 1.0D9 / AIRVOL(I,J,1)
               
               !--------------------------------------------------------
               ! Compute flux of Hg(0) from the ocean to the air
               !--------------------------------------------------------

               ! Compute ocean flux of Hg0 [cm/h*ng/L]
               FLUX(I,J,NN)  = Kw * ( CHg0aq - ( CHg0 / H ) )     

               ! TURN OFF EVASION
!               FLUX(I,J,NN)= MIN(0.,FLUX(I,J,NN))

               
               !Xtra diagnostic: compute flux up and flux down
               FUP(I,J,NN)   = ( Kw * CHg0aq )
               FDOWN(I,J,NN) = ( Kw * CHg0 / H )                          


               ! Convert [cm/h*ng/L] --> [kg/m2/s] --> [kg/s]
               ! Also account for ocean fraction of grid box
               FLUX(I,J,NN)  = FLUX(I,J,NN) * TO_KGM2S * A_M2 * FRAC_O 

               FUP(I,J,NN)  = FUP(I,J,NN) * TO_KGM2S * A_M2 * FRAC_O
               FDOWN(I,J,NN)  = FDOWN(I,J,NN) * TO_KGM2S * A_M2 * FRAC_O
               !--------------------------------------------------------
               ! Flux limited by ocean and atm Hg(0)
               !--------------------------------------------------------

               ! Cap the flux w/ the available Hg(0) ocean mass
               IF ( FLUX(I,J,NN) * DTSRCE > Hg0aq(I,J,NN) ) THEN 
                  FLUX(I,J,NN) = Hg0aq(I,J,NN) / DTSRCE 
                  FUP(I,J,NN)  = FLUX(I,J,NN)-FDOWN(I,J,NN)
               ENDIF
               
               ! Cap FUP with available Hg(0) ocean mass (eck)
!               IF (FUP(I,J,NN)*DTSRCE>Hg0aq(I,J,NN)) THEN
!                  FUP(I,J,NN) = Hg0aq(I,J,NN)/DTSRCE
!               ENDIF

                
               ! Cap the neg flux w/ the available Hg(0) atm mass
               IF ( (-FLUX(I,J,NN) * DTSRCE ) > STT(I,J,1,N) ) THEN
                  FLUX(I,J,NN) = -STT(I,J,1,N) / DTSRCE       
               ENDIF
                
               
               ! Cap FDOWN with available Hg(0) atm mass

!               IF ((FDOWN(I,J,NN)*DTSRCE)>STT(I,J,1,N)) THEN
!                  FDOWN(I,J,NN) = STT(I,J,1,N) / DTSRCE
!               ENDIF

               !--------------------------------------------------------
               ! Remove amt of Hg(0) that is leaving the ocean [kg]
               !--------------------------------------------------------
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN) - ( FLUX(I,J,NN) * DTSRCE ) 

               ! Make sure Hg0aq does not underflow (cdh, bmy, 3/28/06)
               Hg0aq(I,J,NN) = MAX( Hg0aq(I,J,NN), SMALLNUM )

!               Hgaq_tot = HgC(I,J) + Hg0aq(I,J,NN) + Hg2aq(I,J,NN)
               Hgaq_tot = HgPaq(I,J) + Hg0aq(I,J,NN) + Hg2aq(I,J,NN)

            ENDDO   

            !-----------------------------------------------------------
            ! ND03 diagnostics ("OCEAN-HG")
            !-----------------------------------------------------------
            IF ( ND03 > 0 ) THEN

               ! Aqueous Hg(0) mass [kg]
               AD03(I,J,2)  = AD03(I,J,2)  + Hg0aq(I,J,ID_Hg_tot) 

               ! Aqueous Hg(II) mass [kg] 
               AD03(I,J,7)  = AD03(I,J,7)  + Hg2aq(I,J,ID_Hg_tot) 

               ! Hg2 sunk deep into the ocean [kg/time]
               AD03(I,J,8)  = AD03(I,J,8)  + HgPaq_SUNK

               ! HgTot aqua mass [kg] 
               AD03(I,J,10) =AD03(I,J,10) + Hgaq_tot        
 
               ! HgP ocean mass [kg]
!               AD03(I,J,11) = AD03(I,J,11) + HgC(I,J) 
               AD03(I,J,11) = AD03(I,J,11) + HgPaq(I,J) 

               ! flux up and down (eck)
               AD03(I,J,16) = AD03(I,J,16) + FUP(I,J,ID_Hg_tot)*DTSRCE
               AD03(I,J,17) = AD03(I,J,17) + FDOWN(I,J,ID_Hg_tot)*DTSRCE

            ENDIF

           
         !==============================================================
         ! If we are not in an ocean box, set Hg(0) flux to zero
         !==============================================================
         ELSE

            DO NN = 1, N_Hg_CATS 
               FLUX(I,J,NN) = 0d0
               FUP(I,J,NN)=0d0
               FDOWN(I,J,NN)=0d0
            ENDDO               

         ENDIF 
      
         !==============================================================
         ! Zero amts of deposited Hg2 for next timestep [kg]  
         !==============================================================
         
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      !=================================================================
      ! Check tagged & total sums (if necessary)
      !=================================================================
      IF ( USE_CHECKS .and. LSPLIT ) THEN
         CALL CHECK_ATMOS_MERCURY(  'end of OCEAN_MERCURY_FLUX' )
         CALL CHECK_OCEAN_MERCURY(  'end of OCEAN_MERCURY_FLUX' )
         CALL CHECK_OCEAN_FLUXES (  'end of OCEAN_MERCURY_FLUX' )
         CALL CHECK_FLUX_OUT( FLUX, 'end of OCEAN_MERCURY_FLUX' )
      ENDIF

      ! Return to calling program
      END SUBROUTINE OCEAN_MERCURY_FLUX

!------------------------------------------------------------------------------

      SUBROUTINE OCEAN_MERCURY_READ( THISMONTH )
!
!******************************************************************************
!  Subroutine OCEAN_MERCURY_READ reads in the mixed layer depth, net primary 
!  productivity, upwelling and radiation climatology for each month.  
!  This is needed for the ocean flux computation. 
!  (sas, cdh, bmy, 1/20/05, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) THISMONTH (INTEGER) : Month to read fields (1-12)
!
!  NOTES:
!  (1 ) Modified for S. Strode's latest ocean Hg code.  Now read files
!        from DATA_DIR_1x1/mercury_200511. (sas, cdh, bmy, 3/28/06)
!******************************************************************************
!
      ! References to F90 modules
      USE BPCH2_MOD
      USE DIRECTORY_MOD, ONLY : DATA_DIR_1x1, DATA_DIR
      USE TRANSFER_MOD,  ONLY : TRANSFER_2D

#     include "CMN_SIZE"      ! Size parameters

      ! Arguments
      INTEGER, INTENT(IN)    :: THISMONTH

      ! Local Variables
      LOGICAL, SAVE          :: FIRST = .TRUE.
      REAL*4                 :: ARRAY(IGLOB,JGLOB,1)
      REAL*8                 :: TAU
      CHARACTER(LEN=255)     :: FILENAME
     
      !=================================================================
      ! OCEAN_MERCURY_READ begins here!
      !=================================================================
     
      !------------------------------
      ! Mixed layer depth [cm]
      !------------------------------

      ! MLD file name
      FILENAME = TRIM( DATA_DIR )       // 
     &           'mercury_201007/MLD_DReqDT.geos.' // GET_RES_EXT()  
     
      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
 100  FORMAT( '     - OCEAN_MERCURY_READ: Reading ', a )  

      ! TAU0 value (uses year 2003) !(uses year 1985, anls)
      TAU = GET_TAU0( THISMONTH, 1, 1985 )

      ! Read from disk; original units are [m]
      CALL READ_BPCH2( FILENAME, 'BXHGHT-$',    5,  
     &                 TAU,       IGLOB,        JGLOB,      
     &                 1,         ARRAY(:,:,1), QUIET=.TRUE. )

      ! Resize and cast to REAL*8
      CALL TRANSFER_2D( ARRAY(:,:,1), MLD )

      ! Convert [m] to [cm]
      MLD = MLD * 100d0

      ! First-time only: Set MDLav [cm] to MLD of first month
      IF ( FIRST ) THEN   
         MLDav = MLD   
         dMLD  = 0.0
         FIRST = .FALSE.
      ENDIF

!-------------------------------------------------      (anls, 090520) chl
! Chl from Modis [mg/m3]                                only for 4x5 for now  
!-------------------------------------------------

      ! Chl file name
      FILENAME = TRIM( DATA_DIR )       // 
     &           'mercury_201007/Chl_2003.geos.' // GET_RES_EXT()

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! TAU0 values (uses year 2003)
      TAU = GET_TAU0( THISMONTH, 1, 2003 )      

      ! Read data
      CALL READ_BPCH2( FILENAME, 'CHLO-A-$',    1,  
     &                 TAU,       IGLOB,        JGLOB,      
     &                 1,         ARRAY(:,:,1), QUIET=.FALSE. )

      ! Resize and cast to REAL*8
      CALL TRANSFER_2D( ARRAY(:,:,1), CHL )


      !--------------------------------
      ! Net primary productivity [mg/m2/day]
      !--------------------------------
 
      ! NPP file name (anls, 100111)
      FILENAME = TRIM( DATA_DIR )       // 
     &           'mercury_201007/NPP_2003.geos.' // GET_RES_EXT()

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! TAU0 values (uses year 2003)
      TAU = GET_TAU0( THISMONTH, 1, 2003 )
 
      ! Read data
      CALL READ_BPCH2( FILENAME, 'GLOB-NPP',    1,  
     &                 TAU,       IGLOB,        JGLOB,      
     &                 1,         ARRAY(:,:,1), QUIET=.TRUE. )

      ! Resize and cast to REAL*8
      CALL TRANSFER_2D( ARRAY(:,:,1), NPP )
  

      !---------------------------------
      ! Ekman upwelling velocity [cm/s]
      !---------------------------------

      ! NPP file name
      FILENAME = TRIM( DATA_DIR_1x1 )               // 
     &           'mercury_200511/ekman_upvel.geos.' // GET_RES_EXT() 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! TAU0 value (uses year 1985)
      TAU = GET_TAU0( THISMONTH, 1, 1985 )

      ! Read from disk; original units are [cm/s]
      CALL READ_BPCH2( FILENAME, 'EKMAN-V',     1,  
     &                 TAU,       IGLOB,        JGLOB,      
     &                 1,         ARRAY(:,:,1), QUIET=.TRUE. )

      ! Resize and cast to REAL*8
      CALL TRANSFER_2D( ARRAY(:,:,1), UPVEL )

      ! convert [cm/s] to [m/s]
      UPVEL = UPVEL * 1.D-2
  
      ! Return to calling program
      END SUBROUTINE OCEAN_MERCURY_READ

!------------------------------------------------------------------------------

      SUBROUTINE GET_MLD_FOR_NEXT_MONTH( THISMONTH )
!
!******************************************************************************
!  Subroutine GET_MLD_FOR_NEXT_MONTH reads the mixed-layer depth (MLD) 
!  values for the next month. (sas, cdh, bmy, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) THISMONTH (INTEGER) : Current month number (1-12)
!
!  NOTES:
!  (1 ) Now read files from DATA_DIR_1x1/mercury_200511 (bmy, 3/28/06)
!******************************************************************************
!
      ! References to F90 modules
      USE BPCH2_MOD,     ONLY : GET_TAU0, GET_RES_EXT, READ_BPCH2
      USE DIRECTORY_MOD, ONLY : DATA_DIR
      USE TRANSFER_MOD,  ONLY : TRANSFER_2D

#     include "CMN_SIZE"      ! Size parameters

      ! Arguments
      INTEGER, INTENT(IN)    :: THISMONTH

      ! Local variables
      INTEGER                :: I, J, NEXTMONTH
      REAL*4                 :: ARRAY(IGLOB,JGLOB,1)
      REAL*8                 :: TAU
      CHARACTER(LEN=255)     :: FILENAME

      !=================================================================
      ! GET_MLD_FOR_NEXT_MONTH begins here!
      !=================================================================
      
      ! MLD file name
      FILENAME = TRIM( DATA_DIR )       // 
     &           'mercury_201007/MLD_DReqDT.geos.' // GET_RES_EXT()      

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
 100  FORMAT( '     - GET_MLD_FOR_NEXT_MONTH: Reading ', a )  
      
      ! Get the next month
      NEXTMONTH = MOD( THISMONTH, 12 ) +1

      ! TAU0 value for next month (uses year 1985)
      TAU       = GET_TAU0( NEXTMONTH, 1, 1985 )

      ! Read from disk; original units are [m]
      CALL READ_BPCH2( FILENAME, 'BXHGHT-$',    5,  
     &                 TAU,       IGLOB,        JGLOB,      
     &                 1,         ARRAY(:,:,1), QUIET=.TRUE. )

      ! Resize and cast to REAL*8
      CALL TRANSFER_2D( ARRAY(:,:,1), newMLD )

      ! Convert [m] to [cm]
      newMLD = newMLD * 100d0

      ! get rate of change of MLD; convert [cm/month] -> [cm/s] 
      DO J = 1, JJPAR
      DO I = 1, IIPAR
         dMLD(I,J) = (newMLD(I,J) - MLD(I,J)) / ( 3.6d3 *24d0 * 30.5d0 )
      ENDDO
      ENDDO

      ! Return to calling program
      END SUBROUTINE GET_MLD_FOR_NEXT_MONTH

!------------------------------------------------------------------------------

      SUBROUTINE MLD_ADJUSTMENT( I, J, MLDold, MLDnew )
!
!******************************************************************************
!  Subroutine MLD_ADJUSTMENT entrains new water when mixed layer depth deepens
!  and conserves concentration (leaves mass behind) when mixed layer shoals.
!  (sas, cdh, bmy, 4/18/05, 3/28/06)
!  The MLD depth is constrained so that the mean monthly concentration equals
!  the concentration in the middle of the given month. The MLD hereafter 
!  changes linearily until it reaches the middle of the next months where the 
!  process is repeted (anls, 4/30/09)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I      (INTEGER) : GEOS-CHEM longitude index
!  (2 ) J      (INTEGER) : GEOS-CHEM latitude index
!  (3 ) MLDold (REAL*8 ) : Old ocean mixed layer depth [m]
!  (4 ) MLDnew (REAL*8 ) : New ocean mixed layer depth [m]
!
!  NOTES:
!******************************************************************************
!
      ! Reference to fortran90 modules
      USE GRID_MOD,     ONLY : GET_AREA_M2, GET_XMID, GET_YMID !(X,Y added, anls 01/05/09)
      USE LOGICAL_MOD,  ONLY : LSPLIT
      USE TRACER_MOD,   ONLY : TRACER_MW_KG
      USE TRACERID_MOD, ONLY : ID_Hg_tot, ID_Hg_oc, N_Hg_CATS

#     include "CMN_SIZE"     ! Size parameters
#     include "CMN_DEP"      ! FRCLND
      
      ! Arguments
      INTEGER, INTENT(IN)   :: I, J 
      REAL*8,  INTENT(IN)   :: MLDold, MLDnew  

      ! Local variables
      INTEGER               :: C,    NN,     N_tot_oc    
      INTEGER               :: K, L
      REAL*8                :: A_M2, DELTAH, FRAC_O,  MHg
      REAL*8                :: X, Y                   !(added anls 01/05/09)

      !=================================================================
      ! MLD_ADJUSTMENT begins here!
      !=================================================================

      ! Loop limit for use below
      IF ( LSPLIT ) THEN
         N_tot_oc = 2
      ELSE
         N_tot_oc = 1
      ENDIF

      ! Grid box surface area [m2]
      A_M2   = GET_AREA_M2( J )

      ! Fraction of box that is ocean
      FRAC_O = 1d0 - FRCLND(I,J)
      
      ! Molecular weight of Hg (valid for all tagged tracers)
      MHg    = TRACER_MW_KG(ID_Hg_tot)

      ! Test if MLD increased
      IF ( MLDnew > MLDold ) THEN

         !==============================================================
         ! IF MIXED LAYER DEPTH HAS INCREASED:
         !
         ! Entrain water with a concentration specified by CDeep
         !
         ! Entrained Mass = ( Vol water entrained ) * CDeep * Molar mass
         !                = ( DELTAH * AREA * FRAC_O ) * CDeep * MHg
         !==============================================================

         ! Increase in MLD [m]
         DELTAH = MLDnew - MLDold

         ! Add Cdeepatl to North Atlantic and Cdeep to rest if the world (anls, 01/05/09)

         ! Grid-box latitude [degrees]
         Y = GET_YMID( J )
         
         ! Grid box longitude [degrees]
         X = GET_XMID( I )

         ! Loop over total Hg (and ocean Hg if necessary)
         DO C = 1, N_tot_oc

            ! Get Hg category number
            IF ( C == 1 ) NN = ID_Hg_tot
            IF ( C == 2 ) NN = ID_Hg_oc

            ! Atlantic
            IF ( ( X >= -80.0 .and. X < 25.0 )  .and.
     &           ( Y >=  -25.0 .and. Y <  55.0 ) ) THEN !(anls,100114)
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeepatl(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeepatl(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeepatl(3) * MHg * A_M2 * FRAC_O )

                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeepatl(3) * MHg * A_M2 * FRAC_O )

               ENDIF
  
            ! North Pacific (west) 
            ELSE IF ( ( X >= -180.0 .and. X < -80.0 )  .and.
     &              ( Y >=  30.0 .and. Y <  70.0 ) ) THEN
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeepnpa(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeepnpa(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeepnpa(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeepnpa(3) * MHg * A_M2 * FRAC_O )
               ENDIF

            ! North Pacific (east) 
            ELSE IF ( ( X >= 25.0 .and. X < 180.0 )  .and.
     &              ( Y >=  30.0 .and. Y <  70.0 ) ) THEN
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeepnpa(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeepnpa(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeepnpa(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeepnpa(3) * MHg * A_M2 * FRAC_O )
               ENDIF

            ! North Atlantic
            ELSE IF ( ( X >= -80.0 .and. X < 25.0 )  .and.
     &              ( Y >=  55.0 .and. Y <  70.0 ) ) THEN
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeepnat(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeepnat(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeepnat(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeepnat(3) * MHg * A_M2 * FRAC_O )

               ENDIF

            ! South Atlantic
            ELSE IF ( ( X >= -80.0 .and. X < 25.0 )  .and.
     &              ( Y >=  -65.0 .and. Y <  -25.0 ) ) THEN    !(anls,100114)
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeepsat(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeepsat(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeepsat(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeepsat(3) * MHg * A_M2 * FRAC_O )

               ENDIF

            ! Antarctic
            ELSE IF ( Y >=  -90.0 .and. Y <  -65.0 ) THEN
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeepant(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeepant(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeepant(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeepant(3) * MHg * A_M2 * FRAC_O )

               ENDIF


            ! Arctic
            ELSE IF ( Y >=  70.0 .and. Y <  90.0 ) THEN
                        
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                 + ( DELTAH * CDeeparc(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                 + ( DELTAH * CDeeparc(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                 + ( DELTAH * CDeeparc(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                 + ( DELTAH * CDeeparc(3) * MHg * A_M2 * FRAC_O )

               ENDIF

            ELSE
               ! Hg0
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN)
     &                    + ( DELTAH * CDeep(1) * MHg * A_M2 * FRAC_O )

               ! Hg2
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN)
     &                    + ( DELTAH * CDeep(2) * MHg * A_M2 * FRAC_O )

               ! HgP
               IF ( C == 1 ) THEN
!                  HgC(I,J)   = HgC(I,J)          
!     &                    + ( DELTAH * CDeep(3) * MHg * A_M2 * FRAC_O )
                  HgPaq(I,J)   = HgPaq(I,J)          
     &                    + ( DELTAH * CDeep(3) * MHg * A_M2 * FRAC_O )
               ENDIF

            ENDIF
         ENDDO
               
      ELSE 

         !==============================================================
         ! IF MIXED LAYER DEPTH HAS DECREASED:
         !
         ! Conserve concentration, but shed mass for ALL tracers.  
         ! Mass changes by same ratio as volume.
         !==============================================================

         ! Avoid dividing by zero
         IF ( MLDold > 0d0 ) THEN

            ! Update Hg0 and Hg2 categories
            DO NN = 1, N_Hg_CATS
               Hg0aq(I,J,NN) = Hg0aq(I,J,NN) * ( MLDnew / MLDold )
               Hg2aq(I,J,NN) = Hg2aq(I,J,NN) * ( MLDnew / MLDold )
            ENDDO
            
            ! Update colloidal Hg
!            HgC(I,J) = HgC(I,J) * ( MLDnew / MLDold )
            HgPaq(I,J) = HgPaq(I,J) * ( MLDnew / MLDold )
         
         ENDIF

      ENDIF
      
      ! Return to calling program
      END SUBROUTINE MLD_ADJUSTMENT

!------------------------------------------------------------------------------

      SUBROUTINE READ_OCEAN_Hg_RESTART( YYYYMMDD, HHMMSS ) 
!
!******************************************************************************
!  Subroutine READ_OCEAN_Hg_RESTART initializes GEOS-CHEM oceanic mercury 
!  tracer masses from a restart file. (sas, cdh, bmy, 3/28/06)
!
!  Arguments as input:
!  ============================================================================
!  (1 ) YYYYMMDD : Year-Month-Day 
!  (2 ) HHMMSS   :  and Hour-Min-Sec for which to read restart file
! 
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE BPCH2_MOD,        ONLY : OPEN_BPCH2_FOR_READ
      USE DEPO_MERCURY_MOD, ONLY : SNOW_HG, CHECK_DIMENSIONS
      USE DIRECTORY_MOD,    ONLY : RUN_DIR
      USE ERROR_MOD,        ONLY : DEBUG_MSG
      USE FILE_MOD,         ONLY : IU_FILE,     IOERROR
      USE LOGICAL_MOD,      ONLY : LSPLIT,      LPRT
      USE TIME_MOD,         ONLY : EXPAND_DATE
      USE TRACER_MOD,       ONLY : STT,         TRACER_NAME, TRACER_MW_G
      USE TRACERID_MOD,     ONLY : GET_Hg0_CAT, GET_Hg2_CAT, N_Hg_CATS
      USE TRACERID_MOD,     ONLY : ID_Hg0,      ID_Hg2

#     include "CMN_SIZE"     ! Size parameters

      ! Arguments
      INTEGER, INTENT(IN)   :: YYYYMMDD, HHMMSS

      ! Local Variables
      INTEGER               :: I, IOS, J, L, NN, N_oc
      INTEGER               :: YEAR, MONTH, DAY
      INTEGER               :: NCOUNT(NNPAR) 
      REAL*4                :: Hg_OCEAN(IIPAR,JJPAR,1)
      CHARACTER(LEN=255)    :: FILENAME

      ! For binary punch file, version 2.0
      INTEGER               :: NI,        NJ,      NL
      INTEGER               :: IFIRST,    JFIRST,  LFIRST
      INTEGER               :: NTRACER,   NSKIP
      INTEGER               :: HALFPOLAR, CENTER180
      REAL*4                :: LONRES,    LATRES
      REAL*8                :: ZTAU0,     ZTAU1
      CHARACTER(LEN=20)     :: MODELNAME
      CHARACTER(LEN=40)     :: CATEGORY
      CHARACTER(LEN=40)     :: UNIT     
      CHARACTER(LEN=40)     :: RESERVED

      !=================================================================
      ! READ_OCEAN_Hg_RESTART begins here!
      !=================================================================

      ! Initialize some variables
      NCOUNT(:)       = 0
      Hg_OCEAN(:,:,:) = 0e0

      ! Copy input file name to a local variable
      FILENAME        = TRIM( RUN_DIR ) // TRIM( Hg_RST_FILE )

      ! Replace YYYY, MM, DD, HH tokens in FILENAME w/ actual values
      CALL EXPAND_DATE( FILENAME, YYYYMMDD, HHMMSS )

      ! Echo some input to the screen
      WRITE( 6, '(a)' ) REPEAT( '=', 79 )
      WRITE( 6, 100   ) 
      WRITE( 6, 110   ) TRIM( FILENAME )
 100  FORMAT( 'O C E A N   H g   R E S T A R T   F I L E   I N P U T' )
 110  FORMAT( /, 'READ_OCEAN_Hg_RESTART: Reading ', a )

      ! Open the binary punch file for input
      CALL OPEN_BPCH2_FOR_READ( IU_FILE, FILENAME )
      
      ! Echo more output
      WRITE( 6, 120 )
 120  FORMAT( /, 'Min and Max of each tracer, as read from the file:',
     &        /, '(in volume mixing ratio units: v/v)' )
      
      !=================================================================
      ! Read concentrations -- store in the TRACER array
      !=================================================================
      DO 
         READ( IU_FILE, IOSTAT=IOS ) 
     &     MODELNAME, LONRES, LATRES, HALFPOLAR, CENTER180

         ! IOS < 0 is end-of-file, so exit
         IF ( IOS < 0 ) EXIT

         ! IOS > 0 is a real I/O error -- print error message
         IF ( IOS > 0 ) CALL IOERROR( IOS, IU_FILE, 'rd_oc_hg_rst:1' )

         READ( IU_FILE, IOSTAT=IOS ) 
     &        CATEGORY, NTRACER,  UNIT, ZTAU0,  ZTAU1,  RESERVED,
     &        NI,       NJ,       NL,   IFIRST, JFIRST, LFIRST,
     &        NSKIP

         IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_FILE, 'rd_oc_hg_rst:2' )

         READ( IU_FILE, IOSTAT=IOS ) 
     &        ( ( ( Hg_OCEAN(I,J,L), I=1,NI ), J=1,NJ ), L=1,NL )

         IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_FILE, 'rd_oc_hg_rst:3' )

         !==============================================================
         ! Assign data from the TRACER array to the STT array.
         !==============================================================
  
         ! Only process concentration data (i.e. mixing ratio)
         IF ( CATEGORY(1:8) == 'OCEAN-HG' ) THEN 

            ! Make sure array dimensions are of global size
            ! (NI=IIPAR; NJ=JJPAR, NL=LLPAR), or stop the run
            CALL CHECK_DIMENSIONS( NI, NJ, NL )

            ! Save into arrays
            IF ( ANY( ID_Hg0 == NTRACER ) ) THEN

               !----------
               ! Hg(0)
               !----------
               
               ! Get the Hg category #
               NN              = GET_Hg0_CAT( NTRACER )

               ! Store ocean Hg(0) in Hg0aq array
               Hg0aq(:,:,NN)   = Hg_OCEAN(:,:,1)
               
               ! Increment NCOUNT
               NCOUNT(NTRACER) = NCOUNT(NTRACER) + 1

            ELSE IF ( ANY( ID_Hg2 == NTRACER ) ) THEN
               
               !----------
               ! Hg(II)
               !----------

               ! Get the Hg category #
               NN              = GET_Hg2_CAT( NTRACER )

               ! Store ocean Hg(II) in Hg2_aq array
               Hg2aq(:,:,NN)   = Hg_OCEAN(:,:,1)

               ! Increment NCOUNT
               NCOUNT(NTRACER) = NCOUNT(NTRACER) + 1

            ELSE IF ( NTRACER == 3 ) THEN

               !----------
               ! Hg(P)
               !----------

               ! Particulate Hg
               HgPaq(:,:)        = Hg_OCEAN(:,:,1)

               ! Increment NCOUNT
               NCOUNT(NTRACER) = NCOUNT(NTRACER) + 1

            ENDIF

            ! CDH snowpack (added following IF)
         ELSE IF ( CATEGORY(1:7) == 'SNOW-HG' ) THEN  
               !----------
               ! Hg in snow
               !----------

               ! Get the Hg category #
               NN              = GET_Hg0_CAT( NTRACER )

               ! Store ocean Hg(0) in Hg0aq array
               SNOW_HG(:,:,NN)   = Hg_OCEAN(:,:,1)
               
               ! Increment NCOUNT
!               NCOUNT(NTRACER) = NCOUNT(NTRACER) + 1
         ENDIF
      ENDDO

      ! Close file
      CLOSE( IU_FILE )      

      !=================================================================
      ! Examine data blocks, print totals, and return
      !=================================================================

      ! Tagged simulation has 17 ocean tracers; otherwise 3
      IF ( LSPLIT ) THEN
         N_oc = 17
      ELSE
         N_oc = 3
      ENDIF

      ! Check for missing or duplicate data blocks
      CALL CHECK_DATA_BLOCKS( N_oc, NCOUNT )

      !=================================================================
      ! Print totals
      !=================================================================

      ! Echo info
      WRITE( 6, 130 )

      ! Hg0
      DO NN = 1, N_Hg_CATS
         WRITE( 6, 140 ) ID_Hg0(NN), TRACER_NAME( Id_Hg0(NN) ), 
     &                   SUM( Hg0aq(:,:,NN) ),  'kg'
      ENDDO

      ! Hg2
      DO NN = 1, N_Hg_CATS
         WRITE( 6, 140 ) ID_Hg2(NN), TRACER_NAME( Id_Hg2(NN) ), 
     &                   SUM( Hg0aq(:,:,NN) ), 'kg'
      ENDDO

      ! HgP
!      WRITE( 6, 140 ) 3, 'HgC       ', SUM( HgC ), 'kg'
      WRITE( 6, 140 ) 3, 'HgP       ', SUM( HgPaq ), 'kg'

      ! Format strings
 130  FORMAT( /, 'Total masses for each ocean tracer: ' ) 
 140  FORMAT( 'Tracer ', i3, ' (', a10, ') ', es12.5, 1x, a4)

      ! Fancy output
      WRITE( 6, '(a)' ) REPEAT( '=', 79 )

      ! Make sure tagged & total tracers sum up
      IF ( USE_CHECKS .and. LSPLIT ) THEN
         CALL CHECK_OCEAN_MERCURY( 'end of READ_OCEAN_Hg_RESTART' )
      ENDIF

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### READ_OCEAN_Hg_RST: read file' )

      ! Return to calling program
      END SUBROUTINE READ_OCEAN_Hg_RESTART

!------------------------------------------------------------------------------

      SUBROUTINE CHECK_DATA_BLOCKS( N_TRACERS, NCOUNT )
!
!******************************************************************************
!  Subroutine CHECK_DATA_BLOCKS checks to see if we have multiple or 
!  missing data blocks for a given tracer. (sas, cdh, bmy, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) N_TRACERS (INTEGER) : Number of tracers
!  (2 ) NCOUNT    (INTEGER) : Ctr array - # of data blocks found per tracer
!
!  NOTES:
!******************************************************************************
!      
      ! References to F90 modules
      USE ERROR_MOD, ONLY : GEOS_CHEM_STOP

#     include "CMN_SIZE"  ! Size parameters

      ! Arguments
      INTEGER, INTENT(IN) :: N_TRACERS, NCOUNT(NNPAR)
  
      ! Local variables
      INTEGER             :: N

      !=================================================================
      ! CHECK_DATA_BLOCKS begins here! 
      !=================================================================

      ! Loop over all tracers
      DO N = 1, N_TRACERS

         ! Stop if a tracer has more than one data block 
         IF ( NCOUNT(N) > 1 ) THEN 
            WRITE( 6, 100 ) N
            WRITE( 6, 120 ) 
            WRITE( 6, '(a)' ) REPEAT( '=', 79 )
            CALL GEOS_CHEM_STOP
         ENDIF
         
         ! Stop if a tracer has no data blocks 
         IF ( NCOUNT(N) == 0 ) THEN
            WRITE( 6, 110 ) N
            WRITE( 6, 120 ) 
            WRITE( 6, '(a)' ) REPEAT( '=', 79 )
            CALL GEOS_CHEM_STOP
         ENDIF
      ENDDO

      ! FORMAT statements
 100  FORMAT( 'More than one record found for tracer : ', i4 )
 110  FORMAT( 'No records found for tracer : ',           i4 ) 
 120  FORMAT( 'STOP in CHECK_DATA_BLOCKS (restart_mod.f)'    )

      ! Return to calling program
      END SUBROUTINE CHECK_DATA_BLOCKS

!------------------------------------------------------------------------------

      SUBROUTINE MAKE_OCEAN_Hg_RESTART( NYMD, NHMS, TAU )
!
!******************************************************************************
!  Subroutine MAKE_OCEAN_Hg_RESTART writes an ocean mercury restart file.
!  (sas, cdh, bmy, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) YYYYMMDD : Year-Month-Date 
!  (2 ) HHMMSS   :  and Hour-Min-Sec for which to create a restart file       
!  (3 ) TAU      : GEOS-CHEM TAU value corresponding to YYYYMMDD, HHMMSS
!  
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE BPCH2_MOD
      USE DEPO_MERCURY_MOD, ONLY : SNOW_HG
      USE DIRECTORY_MOD,    ONLY : RUN_DIR
      USE FILE_MOD,         ONLY : IU_FILE
      USE GRID_MOD,         ONLY : GET_XOFFSET, GET_YOFFSET
      USE LOGICAL_MOD,      ONLY : LSPLIT
      USE TIME_MOD,         ONLY : EXPAND_DATE, GET_TAU
      USE TRACERID_MOD,     ONLY : ID_Hg_tot,   ID_Hg0
      USE TRACERID_MOD,     ONLY : ID_Hg2,      N_Hg_CATS

#     include "CMN_SIZE"     ! Size parameters

      ! Arguments           
      INTEGER, INTENT(IN)   :: NYMD, NHMS
      REAL*8,  INTENT(IN)   :: TAU

      ! Local variables
      INTEGER               :: HALFPOLAR, CENTER180
      INTEGER               :: IFIRST,    JFIRST,   LFIRST
      INTEGER               :: N,         NN
      REAL*4                :: LONRES,    LATRES,   ARRAY(IGLOB,JGLOB,1)
      CHARACTER(LEN=20)     :: MODELNAME
      CHARACTER(LEN=40)     :: CATEGORY,  UNIT,     RESERVED
      CHARACTER(LEN=255)    :: FILENAME

      !=================================================================
      ! MAKE_OCEAN_Hg_RESTART begins here!
      !=================================================================

      ! Initialize values
      IFIRST    = GET_XOFFSET( GLOBAL=.TRUE. ) + 1
      JFIRST    = GET_YOFFSET( GLOBAL=.TRUE. ) + 1
      LFIRST    = 1
      HALFPOLAR = GET_HALFPOLAR()
      CENTER180 = 1
      LONRES    = DISIZE
      LATRES    = DJSIZE
      MODELNAME = GET_MODELNAME()
      CATEGORY  = 'OCEAN-HG'
      RESERVED  = ''
      UNIT      = 'kg'

      ! Expand date in filename
      FILENAME  = TRIM( RUN_DIR ) // Hg_RST_FILE
      CALL EXPAND_DATE( FILENAME, NYMD, NHMS )

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
 100  FORMAT( '     - MAKE_RESTART_FILE: Writing ', a )

      ! Open BPCH file for output
      CALL OPEN_BPCH2_FOR_WRITE( IU_FILE, FILENAME )

      !---------------------------
      ! Total Hg(0) in ocean
      !---------------------------
      N            = ID_Hg0(Id_Hg_tot)
      ARRAY(:,:,1) = Hg0aq(:,:,ID_Hg_tot)

      CALL BPCH2( IU_FILE,   MODELNAME, LONRES,   LATRES,
     &            HALFPOLAR, CENTER180, CATEGORY, N, 
     &            UNIT,      TAU,       TAU,      RESERVED,
     &            IIPAR,     JJPAR,     1,        IFIRST,
     &            JFIRST,    LFIRST,    ARRAY(:,:,1) )

      !---------------------------
      ! Total Hg(II) in ocean
      !---------------------------
      N            = ID_Hg2(ID_Hg_tot)
      ARRAY(:,:,1) = Hg2aq(:,:,ID_Hg_tot)

      CALL BPCH2( IU_FILE,   MODELNAME, LONRES,   LATRES,
     &            HALFPOLAR, CENTER180, CATEGORY, N, 
     &            UNIT,      TAU,       TAU,      RESERVED,
     &            IIPAR,     JJPAR,     1,        IFIRST,
     &            JFIRST,    LFIRST,    ARRAY(:,:,1) )

      !---------------------------
      ! Total HgP in ocean
      !---------------------------
      N            = 3
!      ARRAY(:,:,1) = HgC(:,:)
      ARRAY(:,:,1) = HgPaq(:,:)

      CALL BPCH2( IU_FILE,   MODELNAME, LONRES,   LATRES,
     &            HALFPOLAR, CENTER180, CATEGORY, N, 
     &            UNIT,      TAU,       TAU,      RESERVED,
     &            IIPAR,     JJPAR,     1,        IFIRST,
     &            JFIRST,    LFIRST,    ARRAY(:,:,1) )

      ! Save tagged ocean tracers if present
      IF ( LSPLIT ) THEN

         !------------------------
         ! Tagged Hg(0) in ocean
         !------------------------
         DO NN = 2, N_Hg_CATS
            N            = ID_Hg0(NN)
            ARRAY(:,:,1) = Hg0aq(:,:,NN)

            CALL BPCH2( IU_FILE,   MODELNAME, LONRES,   LATRES,
     &                  HALFPOLAR, CENTER180, CATEGORY, N, 
     &                  UNIT,      TAU,       TAU,      RESERVED,
     &                  IIPAR,     JJPAR,     1,        IFIRST,
     &                  JFIRST,    LFIRST,    ARRAY(:,:,1) )
         ENDDO

         !------------------------
         ! Tagged Hg(II) in ocean
         !------------------------
         DO NN = 2, N_Hg_CATS
            N            = ID_Hg2(NN)
            ARRAY(:,:,1) = Hg2aq(:,:,NN)

            CALL BPCH2( IU_FILE,   MODELNAME, LONRES,   LATRES,
     &                  HALFPOLAR, CENTER180, CATEGORY, N, 
     &                  UNIT,      TAU,       TAU,      RESERVED,
     &                  IIPAR,     JJPAR,     1,        IFIRST,
     &                  JFIRST,    LFIRST,    ARRAY(:,:,1) )
         ENDDO
      ENDIF

      !CDH snowpack
      !---------------------------
      ! Total Hg in snowpack
      !---------------------------
         DO NN = 1, N_Hg_CATS
            CATEGORY     = 'SNOW-HG'
            N            = ID_Hg0(NN)
            ARRAY(:,:,1) = SNOW_HG(:,:,NN)

            CALL BPCH2( IU_FILE,   MODELNAME, LONRES,   LATRES,
     &                  HALFPOLAR, CENTER180, CATEGORY, N, 
     &                  UNIT,      TAU,       TAU,      RESERVED,
     &                  IIPAR,     JJPAR,     1,        IFIRST,
     &                  JFIRST,    LFIRST,    ARRAY(:,:,1) )
         ENDDO

      ! Close file
      CLOSE( IU_FILE )

      ! Make sure tagged & total tracers sum up
      IF ( USE_CHECKS .and. LSPLIT ) THEN
         CALL CHECK_OCEAN_MERCURY( 'end of MAKE_OCEAN_Hg_RESTART' )
      ENDIF

      ! Return to calling program
      END SUBROUTINE MAKE_OCEAN_Hg_RESTART

!------------------------------------------------------------------------------

      SUBROUTINE CHECK_ATMOS_MERCURY( LOC )
!
!******************************************************************************
!  Subroutine CHECK_ATMOS_MERCURY tests whether the total and tagged tracers 
!  the GEOS-CHEM tracer array STT sum properly within each grid box.
!  (cdh, bmy, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) LOC (CHARACTER) : Name of routine where CHECK_ATMOS_MERCURY is called
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE TRACER_MOD,          ONLY : STT
      USE ERROR_MOD,           ONLY : ERROR_STOP
      USE TRACERID_MOD,        ONLY : ID_Hg0,    ID_Hg2,   ID_HgP
      USE TRACERID_MOD,        ONLY : ID_Hg_tot, N_Hg_CATS

#     include "CMN_SIZE"            ! Size parameters

      ! Arguments as Input
      CHARACTER(LEN=*), INTENT(IN) :: LOC

      ! Local variables
      LOGICAL                      :: FLAG
      INTEGER                      :: I,       J,       L
      INTEGER                      :: N,       NN
      REAL*8                       :: Hg0_tot, Hg0_tag, RELERR0, ABSERR0      
      REAL*8                       :: Hg2_tot, Hg2_tag, RELERR2, ABSERR2
      REAL*8                       :: HgP_tot, HgP_tag, RELERRP, ABSERRP

      !=================================================================
      ! CHECK_ATMOS_MERCURY begins here!
      !=================================================================

      ! Set error flags
      FLAG = .FALSE.

      ! Loop over grid boxes
! OMP PARALLEL DO
! OMP+DEFAULT( SHARED )
! OMP+PRIVATE( I,       J,       L,       N,      NN            )
! OMP+PRIVATE( Hg0_tot, RELERR0, ABSERR0                        )
! OMP+PRIVATE( Hg2_tot, RELERR2, ABSERR2                        )
! OMP+PRIVATE( HgP_tot, RELERRP, ABSERRP                        )
! OMP+REDUCTION( +:     Hg0_tag, Hg2_tag, HgP_tag               )
      DO L = 1, LLPAR
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         ! Initialize
         Hg0_tot = 0d0
         Hg0_tag = 0d0
         RELERR0 = 0d0
         ABSERR0 = 0d0
         Hg2_tot = 0d0
         Hg2_tag = 0d0
         RELERR2 = 0d0
         ABSERR2 = 0d0
         HgP_tot = 0d0
         Hgp_tag = 0d0
         RELERRP = 0d0
         ABSERRP = 0d0

         !--------
         ! Hg(0)
         !--------

         ! Total Hg(0)
         N       = ID_Hg0(ID_Hg_tot)
         Hg0_tot = STT(I,J,L,N)

         ! Sum of tagged Hg(0)
         DO NN = 2, N_Hg_CATS
            N       = ID_Hg0(NN) 
            Hg0_tag = Hg0_tag + STT(I,J,L,N)
         ENDDO

         ! Absolute error for Hg0
         ABSERR0 = ABS( Hg0_tot - Hg0_tag )

         ! Relative error for Hg0 (avoid div by zero)
         IF ( Hg0_tot > 0d0 ) THEN
            RELERR0 = ABS( ( Hg0_tot - Hg0_tag ) / Hg0_tot )
         ELSE
            RELERR0 = -999d0
         ENDIF

         !--------
         ! Hg(II)
         !--------

         ! Total Hg(II)
         N       = ID_Hg2(ID_Hg_tot)
         Hg2_tot = STT(I,J,L,N)

         ! Sum of tagged Hg(II)
         DO NN = 2, N_Hg_CATS
            N       = ID_Hg2(NN) 
            Hg2_tag = Hg2_tag + STT(I,J,L,N)
         ENDDO

         ! Absolute error for Hg2
         ABSERR2 = ABS( Hg2_tot - Hg2_tag )

         ! Relative error for Hg2 (avoid div by zero)
         IF ( Hg2_tot > 0d0 ) THEN
            RELERR2 = ABS( ( Hg2_tot - Hg2_tag ) / Hg2_tot )
         ELSE
            RELERR2 = -999d0
         ENDIF

         !--------
         ! HgP
         !--------

         ! Total Hg(P)
         N       = ID_HgP(ID_Hg_tot)
         HgP_tot = STT(I,J,L,N)

         ! Sum of tagged Hg(P)
         DO NN = 2, N_Hg_CATS
            N = ID_HgP(NN)
            IF ( N > 0 ) HgP_tag = HgP_tag + STT(I,J,L,N)
         ENDDO

         ! Absolute error for HgP
         ABSERRP = ABS( HgP_tot - HgP_tag )

         ! Relative error for HgP (avoid div by zero)
         IF ( HgP_tot > 0d0 ) THEN
            RELERRP = ABS( ( HgP_tot - HgP_tag ) / HgP_tot )
         ELSE
            RELERRP = -999d0
         ENDIF

         !----------------------------
         ! Hg(0) error is too large
         !----------------------------
         IF ( RELERR0 > MAX_RELERR .and. ABSERR0 > MAX_ABSERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 100 ) I, J, L, Hg0_tot, Hg0_tag, RELERR0, ABSERR0
! OMP END CRITICAL
         ENDIF

         !----------------------------
         ! Hg(0) error is too large
         !----------------------------
         IF ( RELERR2 > MAX_RELERR .and. ABSERR2 > MAX_ABSERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 110 ) I, J, L, Hg2_tot, Hg2_tag, RELERR2, ABSERR2
! OMP END CRITICAL
         ENDIF

         !----------------------------
         ! HgP error is too large
         !----------------------------
         IF ( RELERRP > MAX_RELERR .and. ABSERRP > MAX_ABSERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 120 ) I, J, L, HgP_tot, HgP_tag, RELERRP, ABSERRP
! OMP END CRITICAL
         ENDIF
      ENDDO
      ENDDO
      ENDDO
! OMP END PARALLEL DO

      ! FORMAT strings
 100  FORMAT( 'Hg0 error: ', 3i5, 4es13.6 )
 110  FORMAT( 'Hg2 error: ', 3i5, 4es13.6 )
 120  FORMAT( 'HgP error: ', 3i5, 4es13.6 )
 
      ! Stop if Hg0 and Hg2 errors are too large
      IF ( FLAG ) THEN
         CALL ERROR_STOP( 'Tagged Hg0, Hg2, HgP do not add up!', LOC )
      ENDIF

      ! Return to calling program 
      END SUBROUTINE CHECK_ATMOS_MERCURY

!------------------------------------------------------------------------------

      SUBROUTINE CHECK_OCEAN_MERCURY( LOC )
!
!******************************************************************************
!  Subroutine CHECK_TAGGED_HG_OC tests whether tagged tracers in Hg0aq and
!  Hg2aq add properly within each grid box. (cdh, bmy, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) LOC (CHARACTER) : Name of routine where CHECK_OCEAN_MERCURY is called
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,           ONLY : ERROR_STOP
      USE LOGICAL_MOD,         ONLY : LSPLIT
      USE TRACERID_MOD,        ONLY : ID_Hg_tot, N_Hg_CATS

#     include "CMN_SIZE"            ! Size parameters

      ! Arguments
      CHARACTER(LEN=*), INTENT(IN) :: LOC

      ! Local variables
      LOGICAL, SAVE                :: FIRST = .TRUE.
      LOGICAL                      :: FLAG
      INTEGER                      :: I,       J
      REAL*8                       :: Hg0_tot, Hg0_tag, RELERR0, ABSERR0      
      REAL*8                       :: Hg2_tot, Hg2_tag, RELERR2, ABSERR2

      !=================================================================
      ! CHECK_OCEAN_MERCURY begins here!
      !=================================================================

      ! Set error condition flag
      FLAG = .FALSE.

      ! Loop over ocean surface boxes
! OMP PARALLEL DO
! OMP+DEFAULT( SHARED )
! OMP+PRIVATE( I, J, Hg0_tot, Hg0_tag, RELERR0, ABSERR0 ) 
! OMP+PRIVATE        Hg2_tot, Hg2_tag, RELERR2, ABSERR2 )
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         !--------------------------------------
         ! Relative and absolute errors for Hg0 
         !--------------------------------------
         Hg0_tot = Hg0aq(I,J,ID_Hg_tot)
         Hg0_tag = SUM( Hg0aq(I,J,2:N_Hg_CATS) )
         ABSERR0 = ABS( Hg0_tot - Hg0_tag )

         ! Avoid div by zero
         IF ( Hg0_tot > 0d0 ) THEN
            RELERR0 = ABS( ( Hg0_tot - Hg0_tag ) / Hg0_tot )
         ELSE
            RELERR0 = -999d0
         ENDIF

         !--------------------------------------
         ! Relative and absolute errors for Hg2
         !--------------------------------------
         Hg2_tot = Hg2aq(I,J,ID_Hg_tot)
         Hg2_tag = SUM( Hg2aq(I,J,2:N_Hg_CATS) )
         ABSERR2 = ABS( Hg2_tot - Hg2_tag )

         ! Avoid div by zero
         IF ( Hg2_tot > 0d0 ) THEN
            RELERR2 = ABS( ( Hg2_tot - Hg2_tag ) / Hg2_tot )
         ELSE
            RELERR2 = -999d0
         ENDIF

         !--------------------------------------
         ! Hg(0) error is too large
         !--------------------------------------
         IF ( RELERR0 > MAX_RELERR .and. ABSERR0 > MAX_ABSERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 100 ) I, J, Hg0_tot, Hg0_tag, RELERR0, ABSERR0
! OMP END CRITICAL
         ENDIF

         !--------------------------------------
         ! Hg(II) error is too large
         !--------------------------------------
         IF ( RELERR2 > MAX_RELERR .and. ABSERR2 > MAX_ABSERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 110 ) I, J, Hg2_tot, Hg2_tag, RELERR2, ABSERR2
! OMP END CRITICAL
         ENDIF
      ENDDO
      ENDDO
! OMP END PARALLEL DO

      ! FORMAT strings
 100  FORMAT( 'Hg0aq error: ', 2i5, 4es13.6 )
 110  FORMAT( 'Hg2aq error: ', 2i5, 4es13.6 )

      ! Stop if Hg0 and Hg2 errors are too large
      IF ( FLAG ) THEN
         CALL ERROR_STOP( 'Tagged Hg0aq, Hg2aq do not add up!', LOC )
      ENDIF

      ! Return to calling program
      END SUBROUTINE CHECK_OCEAN_MERCURY

!------------------------------------------------------------------------------

      SUBROUTINE CHECK_OCEAN_FLUXES( LOC )
!
!******************************************************************************
!  Subroutine CHECK_OCEAN_FLUXES tests whether the drydep and wetdep fluxes in
!  DD_Hg2 and WD_Hg2 sum together in each grid box. (cdh, bmy, 3/28/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) LOC (CHARACTER) : Name of routine where CHECK_OCEAN_FLUXES is called
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,           ONLY : ERROR_STOP
      USE LOGICAL_MOD,         ONLY : LSPLIT
      USE TRACERID_MOD,        ONLY : ID_Hg_tot, N_Hg_CATS
      USE DEPO_MERCURY_MOD,    ONLY : DD_Hg2, WD_Hg2, DD_HgP, WD_HgP

#     include "CMN_SIZE"            ! Size parameters

      ! Arguments
      CHARACTER(LEN=*), INTENT(IN) :: LOC

      ! Local variables
      LOGICAL                      :: FLAG
      INTEGER                      :: I,         J
      REAL*8                       :: DD_tot,    DD_tag 
      REAL*8                       :: DD_RELERR, DD_ABSERR      
      REAL*8                       :: WD_tot,    WD_tag
      REAL*8                       :: WD_RELERR, WD_ABSERR

      !=================================================================
      ! CHECK_OCEAN_MERCURY begins here!
      !=================================================================

      ! Echo
      WRITE( 6, 100 )
 100  FORMAT( '     - In CHECK_OCEAN_FLUXES' )

      ! Set error condition flag
      FLAG = .FALSE.

      ! Loop over ocean surface boxes
! OMP PARALLEL DO
! OMP+DEFAULT( SHARED )
! OMP+PRIVATE( I, J, DD_tot, DD_tag, DD_RELERR, DD_ABSERR )
! OMP+PRIVATE(       WD_tot, WD_tag, WD_RELERR, WD_ABSERR )
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         !---------------------------------------
         ! Absolute & relative errors for DD_Hg2
         !---------------------------------------
         DD_tot    = DD_Hg2(I,J,1)
         DD_tag    = SUM( DD_Hg2(I,J,2:N_Hg_CATS) )
         DD_ABSERR = ABS( DD_tot - DD_tag ) 

         ! Avoid div by zero
         IF ( DD_tot > 0d0 ) THEN
            DD_RELERR = ABS( ( DD_tot - DD_tag ) / DD_tot )
         ELSE
            DD_RELERR = -999d0
         ENDIF

         !---------------------------------------
         ! Absolute & relative errors for WD_Hg2
         !---------------------------------------
         WD_tot    = WD_Hg2(I,J,1)
         WD_tag    = SUM( WD_Hg2(I,J,2:N_Hg_CATS) )
         WD_ABSERR = ABS( WD_tot - WD_tag )

         ! Avoid div by zero
         IF ( WD_tot > 0d0 ) THEN
            WD_RELERR = ABS( ( WD_tot - WD_tag ) / WD_tot )
         ELSE
            WD_RELERR = -999d0
         ENDIF

         !---------------------------------------
         ! DD flux error is too large
         !---------------------------------------
         IF ( DD_RELERR > MAX_RELERR .and. DD_ABSERR > MAX_FLXERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 110 ) I, J, DD_tot, DD_tag, DD_RELERR, DD_ABSERR
! OMP END CRITICAL
         ENDIF

         !---------------------------------------
         ! WD flux error is too large
         !---------------------------------------
         IF ( WD_RELERR > MAX_RELERR .and. WD_ABSERR > MAX_FLXERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 120 ) I, J, WD_tot, WD_tag, WD_RELERR, WD_ABSERR
! OMP END CRITICAL
         ENDIF
      ENDDO
      ENDDO
! OMP END PARALLEL DO

      ! FORMAT strings
 110  FORMAT( 'DD_Hg2 flux error: ', 2i5, 4es13.6 )
 120  FORMAT( 'WD_Hg2 flux error: ', 2i5, 4es13.6 )

      ! Stop if Hg0 and Hg2 errors are too large
      IF ( FLAG ) THEN
         CALL ERROR_STOP( 'Tagged DD, WD fluxes do not add up!', LOC )
      ENDIf

      ! Return to calling program
      END SUBROUTINE CHECK_OCEAN_FLUXES

!------------------------------------------------------------------------------

      SUBROUTINE CHECK_FLUX_OUT( FLUX, LOC )
!
!******************************************************************************
!  Subroutine CHECK_FLUX_OUT tests whether tagged quantities in FLUX sum 
!  together in each grid box. (cdh, bmy, 3/20/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) FLUX (REAL*8)   : Flux array (output of OCEAN_MERCURY_FLUX)
!  (2 ) LOC (CHARACTER) : Name of routine where CHECK_FLUX_OUT is called
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,           ONLY : ERROR_STOP
      USE LOGICAL_MOD,         ONLY : LSPLIT
      USE TRACERID_MOD,        ONLY : ID_Hg_tot, N_Hg_CATS

#     include "CMN_SIZE"            ! Size parameters

      ! Arguments
      REAL*8,           INTENT(IN) :: FLUX(IIPAR,JJPAR,N_Hg_CATS)            
      CHARACTER(LEN=*), INTENT(IN) :: LOC

      ! Local variables
      LOGICAL                      :: FLAG
      INTEGER                      :: I,          J
      REAL*8                       :: FLX_tot,    FLX_tag
      REAL*8                       :: FLX_RELERR, FLX_ABSERR

      !=================================================================
      ! CHECK_FLUX_OUT begins here!
      !=================================================================

      ! Echo
      WRITE( 6, 100 )
 100  FORMAT( '     - In CHECK_FLUX_OUT' )

      ! Set error condition flag
      FLAG = .FALSE.

      ! Loop over ocean surface boxes
! OMP PARALLEL DO
! OMP+DEFAULT( SHARED )
! OMP+PRIVATE( I, J, FLX_tot, FLX_tag, FLX_err )
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         !----------------------------------------
         ! Absolute & relative errors for FLX_Hg2
         !----------------------------------------
         FLX_tot    = FLUX(I,J,1)
         FLX_tag    = SUM( FLUX(I,J,2:N_Hg_CATS) )
         FLX_ABSERR = ABS( FLX_tot - FLX_tag )
         
         ! Avoid div by zero
         IF ( FLX_tot > 0d0 ) THEN
            FLX_RELERR = ABS( ( FLX_tot - FLX_tag ) / FLX_tot )
         ELSE
            FLX_RELERR = -999d0
         ENDIF

         !----------------------------
         ! Flux error is too large
         !----------------------------
         IF ( FLX_RELERR > MAX_RELERR  .and. 
     &        FLX_ABSERR > MAX_ABSERR ) THEN
! OMP CRITICAL
            FLAG = .TRUE.
            WRITE( 6, 110 ) I, J, FLX_tot,    FLX_tag, 
     &                            FLX_RELERR, FLX_ABSERR
! OMP END CRITICAL
         ENDIF

      ENDDO
      ENDDO
! OMP END PARALLEL DO

      ! FORMAT strings
 110  FORMAT( 'FLX_Hg2 flux error: ', 2i5, 4es13.6 )
 
      ! Stop if Hg0 and Hg2 errors are too large
      IF ( FLAG ) THEN
         CALL ERROR_STOP( 'Tagged emission fluxes do not add up!', LOC )
      ENDIf

      ! Return to calling program
      END SUBROUTINE CHECK_FLUX_OUT

!------------------------------------------------------------------------------

      SUBROUTINE INIT_OCEAN_MERCURY( THIS_Hg_RST_FILE, THIS_USE_CHECKS )
!
!******************************************************************************
!  Subroutine INIT_OCEAN_MERCURY allocates and zeroes module arrays.  
!  (sas, cdh, bmy, 1/19/05, 3/28/06)
!
!  NOTES:
!  (1 ) Now make sure all USE statements are USE, ONLY (bmy, 10/3/05)
!  (2 ) Now just allocates arrays.  We have moved the reading of the ocean
!        Hg restart file to READ_OCEAN_Hg_RESTART.  Now make Hg0aq and Hg2aq
!        3-D arrays. Now pass Hg_RST_FILE and USE_CHECKS from "input_mod.f"
!        via the argument list. (cdh, sas, bmy, 2/27/06)
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,    ONLY : ALLOC_ERR
      USE TRACERID_MOD, ONLY : N_Hg_CATS
      USE LOGICAL_MOD,  ONLY : LPREINDHG

#     include "CMN_SIZE"     ! Size parameters

      ! Arguments
      CHARACTER(LEN=*), INTENT(IN) :: THIS_Hg_RST_FILE
      LOGICAL,          INTENT(IN) :: THIS_USE_CHECKS

      ! Local variables
      INTEGER                      :: AS

      !=================================================================
      ! INIT_OCEAN_MERCURY begins here!
      !=================================================================

      ! Ocean Hg restart file name
      Hg_RST_FILE = THIS_Hg_RST_FILE
      
      ! Turn on error checks for tagged & total sums?
      USE_CHECKS  = THIS_USE_CHECKS
 

      ! Set up concentrations of Hg(0), Hg(II), Hg(C) in deep ocean REDALERT
      IF (LPREINDHG) THEN
         CDEEP    = (/ 2d-11, 1.67d-10, 1.67d-10 /)
         CDEEPATL = (/ 2d-11, 1.67d-10, 1.67d-10 /)
         CDEEPNAT = (/ 2d-11, 1.67d-10, 1.67d-10 /)
         CDEEPSAT = (/ 2d-11, 1.67d-10, 1.67d-10 /)         
         CDEEPANT = (/ 2d-11, 1.67d-10, 1.67d-10 /)
         CDEEPARC = (/ 2d-11, 1.67d-10, 1.67d-10 /)
         CDEEPNPA = (/ 2d-11, 1.67d-10, 1.67d-10 /)
      ELSE
         CDEEP    = (/ 1.0d-10, 4.0d-10, 4.0d-10 /)
         CDEEPATL = (/ 1.4d-10, 9.3d-10, 9.3d-10 /)  
         CDEEPNAT = (/ 1.5d-10, 8.2d-10, 8.2d-10 /)
         CDEEPSAT = (/ 1.0d-10, 5.0d-10, 5.0d-10 /)   !(anls,100114)
         CDEEPANT = (/ 1.0d-10, 3.2d-10, 3.2d-10 /)
         CDEEPARC = (/ 1.2d-10, 7.5d-10, 7.5d-10 /)
         CDEEPNPA = (/ 1.0d-10, 6.0d-10, 6.0d-10 /)        
      ENDIF

      
      ! Allocate arrays
c$$$      ALLOCATE( DD_Hg2( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
c$$$      IF ( AS /= 0 ) CALL ALLOC_ERR( 'DD_Hg2' )
c$$$      DD_Hg2 = 0d0
c$$$
c$$$      ALLOCATE( DD_HgP( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
c$$$      IF ( AS /= 0 ) CALL ALLOC_ERR( 'DD_HgP' )
c$$$      DD_HgP = 0d0

      

      ALLOCATE( dMLD( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'dMLD' )
      dMLD = 0d0

      ALLOCATE( Hg0aq( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'Hg0aq' )
      Hg0aq = 0d0

      ALLOCATE( Hg2aq( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'Hg2aq' )
      Hg2aq = 0d0

!      ALLOCATE( HgC( IIPAR, JJPAR ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'HgC' )
!      HgC = 0d0
      ALLOCATE( HgPaq( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'HgPaq' )
      HgPaq = 0d0

      ALLOCATE( MLD( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'MLD' )
      MLD = 0d0

      ALLOCATE( MLDav( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'MLDav' )
      MLDav = 0d0

      ALLOCATE( newMLD( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'newMLD' )
      newMLD = 0d0

      ALLOCATE( NPP( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'NPP' )
      NPP = 0d0

      ALLOCATE( CHL( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'CHL' )
      CHL = 0d0

!      ALLOCATE( SNOW_HT( IIPAR, JJPAR ), STAT=AS ) !eds
!      IF ( AS /= 0) CALL ALLOC_ERR( 'SNOW_HT' )
!      SNOW_HT = 0d0 

      ALLOCATE( UPVEL( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'UPVEL' )
      UPVEL = 0d0

c$$$      ALLOCATE( WD_Hg2( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
c$$$      IF ( AS /= 0 ) CALL ALLOC_ERR( 'WD_Hg2' )
c$$$      WD_Hg2 = 0d0
c$$$
c$$$      ALLOCATE( WD_HgP( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
c$$$      IF ( AS /= 0 ) CALL ALLOC_ERR( 'WD_HgP' )
c$$$      WD_HgP = 0d0

      ! CDH for snowpack
c$$$      ALLOCATE( SNOW_HG( IIPAR, JJPAR, N_Hg_CATS ), STAT=AS )
c$$$      IF ( AS /= 0 ) CALL ALLOC_ERR( 'SNOW_HG' )
c$$$      SNOW_HG = 0d0
      

      ! Return to calling program
      END SUBROUTINE INIT_OCEAN_MERCURY

!------------------------------------------------------------------------------

      SUBROUTINE CLEANUP_OCEAN_MERCURY
!
!******************************************************************************
!  Subroutine CLEANUP_OCEAN_MERCURY deallocates all arrays.  
!  (sas, cdh, bmy, 1/20/05, 3/28/06)
!  
!  NOTES:
!  (1 ) Now call GET_HALFPOLAR from "bpch2_mod.f" to get the HALFPOLAR flag 
!        value for GEOS or GCAP grids. (bmy, 6/28/05)
!  (2 ) Now just deallocate arrays.  We have moved the writing of the Hg
!        restart file to MAKE_OCEAN_Hg_RESTART.  Now also deallocate HgP, dMLD
!        and MLDav arrays. (sas, cdh, bmy, 3/28/06)
!******************************************************************************
!     
      !=================================================================
      ! CLEANUP_OCEAN_MERCURY begins here!
      !=================================================================
!      IF ( ALLOCATED( DD_Hg2  ) ) DEALLOCATE( DD_Hg2  )
!      IF ( ALLOCATED( DD_HgP  ) ) DEALLOCATE( DD_HgP  )
      IF ( ALLOCATED( dMLD    ) ) DEALLOCATE( dMLD    )
      IF ( ALLOCATED( Hg0aq   ) ) DEALLOCATE( Hg0aq   )  
      IF ( ALLOCATED( Hg2aq   ) ) DEALLOCATE( Hg2aq   )
!      IF ( ALLOCATED( HgC     ) ) DEALLOCATE( HgC     )  
      IF ( ALLOCATED( HgPaq   ) ) DEALLOCATE( HgPaq   )  
      IF ( ALLOCATED( MLD     ) ) DEALLOCATE( MLD     )
      IF ( ALLOCATED( MLDav   ) ) DEALLOCATE( MLDav   )
      IF ( ALLOCATED( newMLD  ) ) DEALLOCATE( newMLD  )
      IF ( ALLOCATED( NPP     ) ) DEALLOCATE( NPP     )
      IF ( ALLOCATED( CHL     ) ) DEALLOCATE( CHL     )
      IF ( ALLOCATED( UPVEL   ) ) DEALLOCATE( UPVEL   )
!      IF ( ALLOCATED( WD_Hg2  ) ) DEALLOCATE( WD_Hg2  )
!      IF ( ALLOCATED( WD_HgP  ) ) DEALLOCATE( WD_HgP  )
!      IF ( ALLOCATED( SNOW_HG ) ) DEALLOCATE( SNOW_HG ) !CDH for snowpack

      ! Return to calling program
      END SUBROUTINE CLEANUP_OCEAN_MERCURY

!------------------------------------------------------------------------------
     
      ! End of module
      END MODULE OCEAN_MERCURY_MOD

