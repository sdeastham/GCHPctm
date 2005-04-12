! $Id: seasalt_mod.f,v 1.5 2005/03/29 15:52:44 bmy Exp $
      MODULE SEASALT_MOD
!
!******************************************************************************
!  Module SEASALT_MOD contains arrays and routines for performing either a
!  coupled chemistry/aerosol run or an offline seasalt aerosol simulation.
!  Original code taken from Mian Chin's GOCART model and modified accordingly.
!  (bec, rjp, bmy, 6/22/00, 2/22/05)
!
!  Seasalt aerosol species: (1) Accumulation mode (0.1 -  2.5 um)  
!                           (2) Coarse mode       (2.5 - 10.0 um)
!
!  Module Variables:
!  ============================================================================
!  (1 ) DRYSALA  (INTEGER) : Drydep index for accumulation mode sea salt
!  (2 ) DRYSALC  (INTEGER) : Drydep index for coarse mode sea salt
!  (3 ) NSALT    (INTEGER) : Number of sea salt tracers
!  (4 ) IDDEP    (INTEGER) : Drydep index array for sea salt tracers
!  (5 ) REDGE    (REAL*8 ) : Array for edges of seasalt radius bins
!  (6 ) RMID     (REAL*8 ) : Array for centers of seasalt radius bins
!  (7 ) SRC      (REAL*8 ) : Array for baseline seasalt emission per bin
!  (8 ) SS_DEN   (REAL*8 ) : Sea salt density [kg/m3]
!
!  Module Routines:
!  ============================================================================
!  (1 ) CHEMSEASALT        : Driver routine for sea salt loss processes
!  (2 ) WET SETTLING       : Routine which performs wet settling of sea salt
!  (3 ) DRY_DEPOSITION     : Routine which performs dry deposition of sea salt
!  (4 ) EMISSSEASALT       : Driver routine for sea salt emissions
!  (5 ) SRCSALT            : Updates surface mixing ratio for sea salt
!  (6 ) INIT_SEASALT       : Allocates all module arrays
!  (7 ) CLEANUP_SEASALT    : Deallocates all module arrays
!
!  GEOS-CHEM modules referenced by "seasalt_mod.f":
!  ============================================================================
!  (1 ) dao_mod.f          : Module w/ arrays for GMAO met fields
!  (2 ) diag_mod.f         : Module w/ GEOS-CHEM diagnostic arrays
!  (3 ) drydep_mod.f       : Module w/ GEOS-CHEM drydep routines
!  (4 ) error_mod.f        : Module w/ I/O error and NaN check routines
!  (5 ) grid_mod.f         : Module w/ horizontal grid information
!  (6 ) logical_mod.f      : Module w/ GEOS-CHEM logical switches
!  (7 ) pbl_mix_mod.f      : Module w/ routines for PBL height & mixing
!  (8 ) pressure_mod.f     : Module w/ routines to compute P(I,J,L)
!  (9 ) time_mod.f         : Module w/ routines to compute date & time
!  (10) tracer_mod.f       : Module w/ GEOS-CHEM tracer array STT etc.
!  (11) tracerid_mod.f     : Module w/ pointers to tracers & emissions 
!
!  References:
!  ============================================================================
!  (1 ) Chin, M., P. Ginoux, S. Kinne, B. Holben, B. Duncan, R. Martin,
!        J. Logan, A. Higurashi, and T. Nakajima, "Tropospheric aerosol
!        optical thickness from the GOCART model and comparisons with
!        satellite and sunphotometers measurements", J. Atmos Sci., 2001.
!  (2 ) Gong, S., L. Barrie, and J.-P. Blanchet, "Modeling sea-salt
!        aerosols in the atmosphere. 1. Model development", J. Geophys. Res.,
!        v. 102, 3805-3818, 1997.
!
!  NOTES:  
!  (1 ) Now references "logical_mod.f" and "tracer_mod.f".  Comment out 
!        SS_SIZE, this has been replaced by SALA_REDGE_um and SALC_REDGE_um
!        from "tracer_mod.f".  Increased NR_MAX to 200. (bmy, 7/20/04)
!  (2 ) Added error check in EMISSSEASALT (bmy, 1/20/05)
!  (3 ) Now references "pbl_mix_mod.f" (bmy, 2/22/05)
!******************************************************************************
!
      IMPLICIT NONE

      !=================================================================
      ! MODULE PRIVATE DECLARATIONS -- keep certain internal variables 
      ! and routines from being seen outside "seasalt_mod.f"
      !=================================================================

      ! Make everyting PRIVATE ...
      PRIVATE

      ! ... except these routines
      PUBLIC :: CHEMSEASALT
      PUBLIC :: EMISSSEASALT
      PUBLIC :: CLEANUP_SEASALT

      !=================================================================
      ! MODULE VARIABLES
      !=================================================================

      ! Scalars
      INTEGER, PARAMETER   :: NSALT = 2
      INTEGER, PARAMETER   :: NR_MAX = 200
      INTEGER              :: DRYSALA, DRYSALC

      ! Arrays
      INTEGER              :: IDDEP(NSALT)
      REAL*8,  ALLOCATABLE :: REDGE(:,:)   
      REAL*8,  ALLOCATABLE :: RMID(:,:)
      REAL*8,  ALLOCATABLE :: SRC(:,:)     
      REAL*8               :: SS_DEN(NSALT)    = (/2200.d0, 2200.d0  /)

      !=================================================================
      ! MODULE ROUTINES -- follow below the "CONTAINS" statement 
      !=================================================================
      CONTAINS

!------------------------------------------------------------------------------

      SUBROUTINE CHEMSEASALT
!
!******************************************************************************
!  Subroutine CHEMSEASALT is the interface between the GEOS-CHEM main program 
!  and the seasalt chemistry routines that mostly calculates seasalt dry 
!  deposition (rjp, bmy, 1/24/02, 7/20/04)
!
!  NOTES:
!  (1 ) Now reference STT from "tracer_mod.f".  Now references LPRT from
!        "logical_mod.f" (bmy, 7/20/04)
!******************************************************************************
!
      ! References to F90 modules
      USE DRYDEP_MOD,   ONLY : DEPNAME, NUMDEP
      USE ERROR_MOD,    ONLY : DEBUG_MSG
      USE LOGICAL_MOD,  ONLY : LPRT
      USE TRACER_MOD,   ONLY : STT
      USE TRACERID_MOD, ONLY : IDTSALA, IDTSALC

#     include "CMN_SIZE"     ! Size parameters 

      ! Local variables
      LOGICAL, SAVE         :: FIRST = .TRUE.
      INTEGER               :: N

      !=================================================================
      ! CHEMSEASALT begins here!
      !=================================================================

      ! First-time initialization
      IF ( FIRST ) THEN

         ! Find drydep species in DEPSAV
         DO N = 1, NUMDEP
            SELECT CASE ( TRIM( DEPNAME(N) ) )
               CASE ( 'SALA' )
                  DRYSALA = N
               CASE ( 'SALC' )
                  DRYSALC = N
               CASE DEFAULT
                  ! Nothing
            END SELECT        
         ENDDO

         ! Store in IDDEP array
         IDDEP(1) = DRYSALA
         IDDEP(2) = DRYSALC

         ! Reset first-time flag
         FIRST = .FALSE.
      ENDIF

      !=================================================================
      ! Maybe someday we should merge these two separate calculations
      ! into one (rjp, 4/3/04)
      !=================================================================

      !-------------------
      ! Accumulation mode
      !-------------------
      CALL WET_SETTLING( STT(:,:,:,IDTSALA), 1 )
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMSEASALT: WET_SET, Accum' )

      CALL DRY_DEPOSITION( STT(:,:,:,IDTSALA), 1 )
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMSEASALT: DRY_DEP, Accum' )

      !-------------------
      ! Coarse mode
      !-------------------
      CALL WET_SETTLING( STT(:,:,:,IDTSALC), 2 )
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMSEASALT: WET_SET, Coarse' )

      CALL DRY_DEPOSITION( STT(:,:,:,IDTSALC), 2 )
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMSEASALT: DRY_DEP, Coarse' )

      ! Return to calling program
      END SUBROUTINE CHEMSEASALT

!------------------------------------------------------------------------------

      SUBROUTINE WET_SETTLING( TC, N )
!
!******************************************************************************
!  Subroutine WET_SETTLING performs wet settling of sea salt.
!  (bec, rjp, bmy, 4/20/04, 7/20/04)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) TC (REAL*8 ) : Sea salt tracer [kg]
!  (2 ) N  (INTEGER) : N=1 is accum mode; N=2 is coarse mode
!
!  Arguments as Output:
!  ============================================================================
!  (1 ) TC (REAL*8 ) : Contains modified tracer
!
!  NOTES:
!  (1 ) Now references SALA_REDGE_um and SALC_REDGE_um from "tracer_mod.f"
!        (bmy, 7/20/04)
!******************************************************************************
!
      ! References to F90 modules
      USE DAO_MOD,       ONLY : T, BXHEIGHT, RH
      USE DIAG_MOD,      ONLY : AD44
      USE DRYDEP_MOD,    ONLY : DEPSAV
      USE PRESSURE_MOD,  ONLY : GET_PCENTER
      USE TRACER_MOD,    ONLY : SALA_REDGE_um, SALC_REDGE_um
      USE TRACERID_MOD,  ONLY : IDTSALA,       IDTSALC
      USE TIME_MOD,      ONLY : GET_TS_CHEM
      USE GRID_MOD,      ONLY : GET_AREA_CM2

#     include "CMN_SIZE"      ! Size parameters
#     include "CMN_GCTM"      ! g0
#     include "CMN_DIAG"      ! ND44
#     include "CMN_O3"        ! XNUMOL

      ! Argumetns
      INTEGER, INTENT(IN)    :: N
      REAL*8,  INTENT(INOUT) :: TC(IIPAR,JJPAR,LLPAR)

      ! Local variables
      INTEGER                :: I,      J,     L,        DTCHEM
      REAL*8                 :: DELZ,   DELZ1, REFF,     DEN
      REAL*8                 :: P,      DP,    PDP,      TEMP        
      REAL*8                 :: CONST,  SLIP,  VISC,     FAC1
      REAL*8                 :: FAC2,   FLUX,  AREA_CM2, RHB
      REAL*8                 :: RCM,    RWET,  RATIO_R,  RHO
      REAL*8                 :: TOT1,   TOT2
      REAL*8                 :: VTS(LLPAR)  
      REAL*8                 :: TC0(LLPAR)
      
      ! Parameters
      REAL*8,  PARAMETER     :: C1 =  0.7674d0 
      REAL*8,  PARAMETER     :: C2 =  3.079d0 
      REAL*8,  PARAMETER     :: C3 =  2.573d-11
      REAL*8,  PARAMETER     :: C4 = -1.424d0

      !=================================================================
      ! WET_SETTLING begins here!
      !=================================================================

      ! Chemistry timestep [s]
      DTCHEM = GET_TS_CHEM() * 60d0

      ! Sea salt density [kg/m3]
      DEN  = SS_DEN( N )

      ! Seasalt effective radius (i.e. midpt of radius bin) [m]
      SELECT CASE ( N )

         ! Accum mode
         CASE( 1 )
            REFF = 0.5d-6 * ( SALA_REDGE_um(1) + SALA_REDGE_um(2) )

         ! Coarse mode
         CASE( 2 ) 
            REFF = 0.5d-6 * ( SALC_REDGE_um(1) + SALC_REDGE_um(2) )
            
      END SELECT

      ! Sea salt radius [cm]
      RCM  = REFF * 100d0  

      ! Exponential factors
      FAC1 = C1 * ( RCM**C2 )
      FAC2 = C3 * ( RCM**C4 )

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,       J,     L,    VTS,  P,        TEMP, RHB,  RWET ) 
!$OMP+PRIVATE( RATIO_R, RHO,   DP,   PDP,  CONST,    SLIP, VISC, TC0  )
!$OMP+PRIVATE( DELZ,    DELZ1, TOT1, TOT2, AREA_CM2, FLUX             )
!$OMP+SCHEDULE( DYNAMIC )
      DO J = 1, JJPAR
      DO I = 1, IIPAR       

         ! Initialize 
         DO L = 1, LLPAR
            VTS(L) = 0d0
         ENDDO

         ! Loop over levels
         DO L = 1, LLPAR

            ! Pressure at center of the level [kPa]
            P       = GET_PCENTER(I,J,L) * 0.1d0

            ! Temperature [K]
            TEMP    = T(I,J,L)

            ! Cap RH at 0.99 
            RHB     = MIN( 0.99d0, RH(I,J,L) * 1d-2 )

            ! Aerosol growth with relative humidity in radius [m] 
            ! (Gerber, 1985)
            RWET    = 0.01d0*(FAC1/(FAC2-DLOG(RHB))+RCM**3.d0)**0.33d0

            ! Ratio dry over wet radii at the cubic power
            RATIO_R = ( REFF / RWET )**3.d0

            ! Density of the wet aerosol (kg/m3)
            RHO     = RATIO_R * DEN + ( 1.d0 - RATIO_R ) * 1000.d0

            ! Dp = particle diameter [um]
            DP      = 2.d0 * RWET * 1.d6        

            ! PdP = P * dP [hPa * um]
            PDp     = P * Dp

            ! Constant
            CONST   = 2.d0 * RHO * RWET**2 * g0 / 9.d0

            !===========================================================
            ! NOTE: Slip correction factor calculations following 
            ! Seinfeld, pp464 which is thought to be more accurate 
            ! but more computation required. (rjp, 1/24/02)
            !
            ! # air molecule number density
            ! num = P * 1d3 * 6.023d23 / (8.314 * Temp) 
            !
            ! # gas mean free path
            ! lamda = 1.d6/( 1.41421 * num * 3.141592 * (3.7d-10)**2 ) 
            !
            ! # Slip correction
            ! Slip = 1. + 2. * lamda * (1.257 + 0.4 * exp( -1.1 * Dp     
            !     &     / (2. * lamda))) / Dp
            !
            ! NOTE: Eq) 3.22 pp 50 in Hinds (Aerosol Technology)
            ! which produces slip correction factore with small error
            ! compared to the above with less computation.
            !===========================================================  
          
            ! Slip correction factor (as function of P*dp)
            Slip = 1.d0+(15.60d0 + 7.0d0 * EXP(-0.059d0 * PDp)) / PDp

            ! Viscosity [Pa*s] of air as a function of temperature 
            VISC = 1.458d-6 * (Temp)**(1.5d0) / ( Temp + 110.4d0 )

            ! Settling velocity [m/s]
            VTS(L) = CONST * Slip / VISC
         ENDDO

         ! Method is to solve bidiagonal matrix which is
         ! implicit and first order accurate in z (rjp, 1/24/02)

         ! Save initial tracer concentration in column
         DO L = 1, LLPAR
            TC0(L) = TC(I,J,L)
         ENDDO

         ! We know the boundary condition at the model top
         L    = LLTROP
         DELZ = BXHEIGHT(I,J,L)

         TC(I,J,L) = TC(I,J,L) / ( 1.d0 + DTCHEM * VTS(L) / DELZ )

         DO L = LLTROP-1, 1, -1
            DELZ  = BXHEIGHT(I,J,L)
            DELZ1 = BXHEIGHT(I,J,L+1)
            TC(I,J,L) = 1.d0 / ( 1.d0 + DTCHEM * VTS(L) / DELZ )
     &                * ( TC(I,J,L) + DTCHEM * VTS(L+1) / DELZ1
     &                *  TC(I,J,L+1) )
         ENDDO
         
         !==============================================================
         ! ND44 diagnostic: sea salt loss [molec/cm2/s]
         !==============================================================
         IF ( ND44 > 0 ) THEN

            ! Initialize
            TOT1 = 0d0
            TOT2 = 0d0
            
            ! Compute column totals of TCO(:) and TC(I,J,:,N)
            DO L = 1, LLPAR
               TOT1 = TOT1 + TC0(L)
               TOT2 = TOT2 + TC(I,J,L)
            ENDDO

            ! Surface area [cm2]
            AREA_CM2 = GET_AREA_CM2( J )

            ! Convert sea salt flux from [kg/s] to [molec/cm2/s]
            FLUX     = ( TOT1 - TOT2 ) / DTCHEM
            FLUX     = FLUX * XNUMOL(IDTSALA) / AREA_CM2 
   
            ! Store in AD44 array
            AD44(I,J,IDDEP(N),1) = AD44(I,J,IDDEP(N),1) + FLUX
         ENDIF
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      ! Return to calling program
      END SUBROUTINE WET_SETTLING

!------------------------------------------------------------------------------

      SUBROUTINE DRY_DEPOSITION( TC, N )
!
!******************************************************************************
!  Subroutine DRY_DEPOSITION computes the loss of sea salt by dry deposition
!  at the surface, using an implicit method. (bec, rjp, bmy, 4/20/04)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) TC (REAL*8 ) : Sea salt tracer [kg]
!  (2 ) N  (INTEGER) : N=1 is accum mode; N=2 is coarse mode
!
!  Arguments as Output:
!  ============================================================================
!  (1 ) TC (REAL*8 ) : Contains modified tracer
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE DIAG_MOD,     ONLY : AD44
      USE DRYDEP_MOD,   ONLY : DEPSAV   
      USE TRACERID_MOD, ONLY : IDTSALA,   IDTSALC
      USE TIME_MOD,     ONLY : GET_MONTH, GET_TS_CHEM
      USE GRID_MOD,     ONLY : GET_AREA_CM2

#     include "CMN_SIZE"     ! Size parameters
#     include "CMN_GCTM"     ! g0
#     include "CMN_DIAG"     ! ND44
#     include "CMN_O3"       ! XNUMOL

      ! Arguments
      INTEGER, INTENT(IN)    :: N
      REAL*8,  INTENT(INOUT) :: TC(IIPAR,JJPAR,LLPAR)

      ! Local variables
      INTEGER                :: I,        J,     L,      DTCHEM
      REAL*8                 :: OLD,      NEW,   G,      REFF
      REAL*8                 :: DIAM,     U_TS0, REYNOL, ALPHA 
      REAL*8                 :: BETA,     GAMMA, DENS,   FLUX 
      REAL*8                 :: AREA_CM2, TOT1,  TOT2

      ! Parameters
      REAL*8,  PARAMETER     :: RHOA = 1.25d-3

      !=================================================================
      ! DRY_DEPOSITION begins here!
      !=================================================================

      ! Chemistry timestep [s]
      DTCHEM = GET_TS_CHEM() * 60d0

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, AREA_CM2, OLD, NEW, FLUX )
!$OMP+SCHEDULE( DYNAMIC )

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area [cm2]
         AREA_CM2 = GET_AREA_CM2( J )

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Old tracer concentration [kg]
            OLD  = TC(I,J,1)

            ! New tracer concentration [kg]
            NEW  = OLD * EXP( -DEPSAV(I,J,IDDEP(N)) * DTCHEM  )

            !===========================================================
            ! ND44 diagnostic: sea salt drydep loss [molec/cm2/s]
            !===========================================================
            IF ( ND44 > 0 ) THEN
               
               ! Convert drydep loss from [kg/s] to [molec/cm2/s]
               FLUX = ( OLD - NEW ) / DTCHEM 
               FLUX = FLUX * XNUMOL(IDTSALA) / AREA_CM2 
            
               ! Store in AD44
               AD44(I,J,IDDEP(N),1) = AD44(I,J,IDDEP(N),1) + FLUX
            ENDIF

            ! Update tracer array
            TC(I,J,1) = NEW 
         ENDDO
      ENDDO
!$OMP END PARALLEL DO

      ! Return to calling program
      END SUBROUTINE DRY_DEPOSITION

!------------------------------------------------------------------------------

      SUBROUTINE EMISSSEASALT
!
!******************************************************************************
!  Subroutine EMISSSEASALT is the interface between the GEOS-CHEM model
!  and the SEASALT emissions routines in "seasalt_mod.f".
!  (bec, rjp, bmy, 3/24/03, 2/22/05)
!
!  NOTES:
!  (1 ) Now references LPRT from "logical_mod.f" and STT from "tracer_mod.f".
!        (bmy, 7/20/04)
!  (2 ) Now make sure IDTSALA, IDTSALC are nonzero before calling SRCSALT.
!        (bmy, 1/26/05)
!  (3 ) Remove reference to header file "CMN" (bmy, 2/22/05)
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,    ONLY : DEBUG_MSG
      USE LOGICAL_MOD,  ONLY : LPRT
      USE TRACER_MOD,   ONLY : STT
      USE TRACERID_MOD, ONLY : IDTSALA, IDTSALC

#     include "CMN_SIZE"     ! Size parameters
!----------------------------------------------
! Prior to 2/22/05:
!#     include "CMN"      ! STT, LPRT
!----------------------------------------------

      !=================================================================
      ! EMISSSEASALT begins here! 
      !=================================================================

      ! Accumulation mode
      IF ( IDTSALA > 0 ) THEN
         CALL SRCSALT( STT(:,:,:,IDTSALA), 1 )
         IF ( LPRT ) CALL DEBUG_MSG( '### EMISSEASALT: Accum' )
      ENDIF

      ! Coarse mode
      IF ( IDTSALC > 0 ) THEN
         CALL SRCSALT( STT(:,:,:,IDTSALC), 2 )
         IF ( LPRT ) CALL DEBUG_MSG( '### EMISSEASALT: Coarse' )
      ENDIF

      ! Return to calling program
      END SUBROUTINE EMISSSEASALT

!-----------------------------------------------------------------------------

      SUBROUTINE SRCSALT( TC, N )
!
!******************************************************************************
!  Subroutine SRCSALT updates the surface mixing ratio of dry sea salt
!  aerosols for NSALT size bins.  The generation of sea salt aerosols
!  has been parameterized following Monahan et al. [1986] parameterization
!  as described by Gong et al. [1997].  (bec, rjp, bmy, 4/20/04, 2/22/05)
! 
!  Contact: Becky Alexander (bec@io.harvard.edu) or 
!           Rokjin Park     (rjp@io.harvard.edu)
! 
!  Arguments as Input:
!  ============================================================================
!  (1 ) TC (REAL*8 ) : Sea salt tracer array [v/v]
!  (2 ) N  (INTEGER) : N=1 denotes accumulation mode; N=2 denotes coarse mode
!
!  Arguments as Output:
!  ============================================================================
!  (1 ) TC (REAL*8 ) : Contains modified sea salt concentration [v/v]
!
!  References:
!  ============================================================================
!  (1 ) Chin, M., P. Ginoux, S. Kinne, B. Holben, B. Duncan, R. Martin,
!        J. Logan, A. Higurashi, and T. Nakajima, "Tropospheric aerosol
!        optical thickness from the GOCART model and comparisons with
!        satellite and sunphotometers measurements", J. Atmos Sci., 2001.
!  (2 ) Gong, S., L. Barrie, and J.-P. Blanchet, "Modeling sea-salt
!        aerosols in the atmosphere. 1. Model development", J. Geophys. Res.,
!        v. 102, 3805-3818, 1997.
! 
!  NOTES:
!  (1 ) Now references SALA_REDGE_um and SALC_REDGE_um from "tracer_mod.f"
!        (bmy, 7/20/04)
!  (2 ) Now references GET_FRAC_OF_PBL and GET_PBL_TOP_L from "pbl_mix_mod.f".
!        Removed reference to header file CMN.  Removed reference to 
!        "pressure_mod.f".  (bmy, 2/22/05)
!******************************************************************************
!
      ! References to F90 modules
      USE DAO_MOD,       ONLY : PBL, AD, IS_WATER 
      USE DIAG_MOD,      ONLY : AD08
      USE ERROR_MOD,     ONLY : DEBUG_MSG, ERROR_STOP
      USE GRID_MOD,      ONLY : GET_AREA_M2
      USE PBL_MIX_MOD,   ONLY : GET_FRAC_OF_PBL, GET_PBL_TOP_L
      !----------------------------------------------------------------
      ! Prior to 2/22/05:
      !USE PRESSURE_MOD,  ONLY : GET_PEDGE
      !----------------------------------------------------------------
      USE TIME_MOD,      ONLY : GET_TS_EMIS
      USE TRACER_MOD,    ONLY : SALA_REDGE_um, SALC_REDGE_um

#     include "CMN_SIZE"      ! Size parameters
!------------------------------------------------------------
! Prior to 2/22/05:
!#     include "CMN"           ! XTRA2
!------------------------------------------------------------
#     include "CMN_O3"        ! XNUMOL
#     include "CMN_DIAG"      ! ND44, ND08
#     include "CMN_GCTM"      ! PI, SCALE_HEIGHT

      ! Arguments
      INTEGER, INTENT(IN)    :: N
      REAL*8,  INTENT(INOUT) :: TC(IIPAR,JJPAR,LLPAR)

      ! Local variables 
      LOGICAL, SAVE          :: FIRST = .TRUE.
      LOGICAL, SAVE          :: FLAG  = .TRUE.
      INTEGER                :: I,    J,      L
      INTEGER                :: R,    NR,     NTOP
      !--------------------------------------------------------------
      ! Prior to 2/22/05:
      !REAL*8                 :: W10M, BLTOP, DTEMIS,  R0
      !REAL*8                 :: R1,   CONST, P1,      P2
      !REAL*8                 :: DELP, FEMIS, SALTSRC, BLTHIK
      !--------------------------------------------------------------
      REAL*8                 :: W10M, DTEMIS, R0
      REAL*8                 :: R1,   CONST,  FEMIS
      REAL*8                 :: A_M2
      REAL*8                 :: SALT(IIPAR,JJPAR)

      ! Increment of radius for Emission integration (um)
      REAL*8, PARAMETER      :: DR    = 5.d-2
      REAL*8, PARAMETER      :: BETHA = 1.d0

      ! External functions
      REAL*8,  EXTERNAL      :: SFCWINDSQR

      !=================================================================
      ! SRCSALT begins here!
      !=================================================================
      
      ! Alllocate arrays
      IF ( FIRST ) THEN
         CALL INIT_SEASALT
         FIRST = .FALSE.
      ENDIF

      ! Emission timestep [s]
      DTEMIS = GET_TS_EMIS() * 60d0

      ! Constant [volume * time * other stuff??] 
      CONST = 4d0/3d0 * PI * DR * DTEMIS * 1.d-18 * 1.373d0

      ! Lower and upper limit of size bin N [um]
      SELECT CASE( N ) 
       
         ! Accum mode
         CASE( 1 )
            R0 = SALA_REDGE_um(1)
            R1 = SALA_REDGE_um(2)
          
         ! Coarse mode
         CASE( 2 )
            R0 = SALC_REDGE_um(1)
            R1 = SALC_REDGE_um(2)
            
      END SELECT


      ! Number of radius size bins
      NR = INT( ( ( R1 - R0 ) / DR ) + 0.5d0 ) 

      ! Error check
      IF ( NR > NR_MAX ) THEN
         CALL ERROR_STOP( 'Too many bins!', 'SRCSALT (seasalt_mod.f)' )
      ENDIF

      ! Initialize source
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J )
      DO J = 1, JJPAR
      DO I = 1, IIPAR
         SALT(I,J) = 0d0
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      !=================================================================
      ! Define edges and midpoints of each incrmental radius bin
      ! This only has to be done once per sea salt type
      !=================================================================
      IF ( FLAG ) THEN 

         ! Lower edge of 0th bin
         REDGE(0,N) = R0
      
         ! Loop over the # of radius bins
         DO R = 1, NR

            ! Midpoint of IRth bin
            RMID(R,N)  = REDGE(R-1,N) + ( DR / 2d0 )

            ! Upper edge of IRth bin
            REDGE(R,N) = REDGE(R-1,N) + DR 

            ! Sea salt base source [kg/m2] ??
            SRC(R,N)  = CONST * SS_DEN( N ) 
     &           * ( 1.d0 + 0.057d0*( BETHA * RMID(R,N) )**1.05d0 )
     &           * 10d0**( 1.19d0*
     &                  EXP(-((0.38d0-LOG(BETHA*RMID(R,N)))/0.65d0)**2))
     &           / BETHA**2         

!### Debug
!###           WRITE( 6, 100 ) R,REDGE(R-1,N),RMID(R,N),REDGE(R,N),SRC(R,N)
!### 100        FORMAT( 'IR, R0, RMID, R1: ', i3, 3f11.4,2x,es13.6 )
         ENDDO
      
         ! Reset only after N=NSALT
         IF ( FLAG .and.  N == NSALT ) FLAG = .FALSE.
      ENDIF
    
      !=================================================================
      ! Emission is integrated over a given size range for each bin
      !=================================================================
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, R, A_M2, W10M )
!$OMP+SCHEDULE( DYNAMIC )

      ! Loop over latitudes
      DO J = 1, JJPAR
            
         ! Grid box surface area [m2]
         A_M2 = GET_AREA_M2( J )

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Test if this is a water box
            IF ( IS_WATER(I,J) ) THEN

               ! Wind speed at 10 m altitude [m/s]
               W10M = SQRT( SFCWINDSQR(I,J) )

               ! Loop over size bins
               DO R = 1, NR

                  ! Update seasalt source into SALT [kg]
                  SALT(I,J) = SALT(I,J) + 
     &                        ( SRC(R,N) * A_M2 * W10M**3.41d0 )

               ENDDO
            ENDIF
         ENDDO
      ENDDO
!$OMP END PARALLEL DO

      !=================================================================
      ! Now partition seasalt emissions through boundary layer
      !=================================================================
!-----------------------------------------------------------------------------
! Prior to 2/22/05:
!!$OMP PARALLEL DO
!!$OMP+DEFAULT( SHARED )
!!$OMP+PRIVATE( I, J,  NTOP, SALTSRC, BLTOP, BLTHIK )
!!$OMP+PRIVATE( L, P1, P2,   DELP,    FEMIS         )
!!$OMP+SCHEDULE( DYNAMIC ) 
!
!         ! Layer where the PBL top happens
!         NTOP = CEILING( XTRA2(I,J) )
!         
!         ! Initialize
!         SALTSRC = 0.d0
!
!         !==============================================================
!         ! PBL height is in the 3rd model layer or higher
!         !==============================================================
!         IF ( NTOP >= 2 ) THEN
!
!#if   defined( GEOS_4 )
!
!            ! BLTOP = pressure at PBL top [hPa]
!            ! Use barometric law since PBL is in [m]
!            BLTOP  = GET_PEDGE(I,J,1) * EXP( -PBL(I,J) / SCALE_HEIGHT )
!
!            ! BLTHIK is PBL thickness [hPa]
!            BLTHIK = GET_PEDGE(I,J,1) - BLTOP
!
!#else
!
!            ! BLTOP = pressure of PBL top [hPa]
!            BLTOP  = GET_PEDGE(I,J,1) - PBL(I,J)
!
!            ! BLTHIK is PBL thickness [hPa]
!            BLTHIK = PBL(I,J)
!
!#endif
!
!            ! Loop thru the boundary layer
!            DO L = 1, NTOP
!
!               ! DELP is the pressure thickness of level L [hPa]
!               P1   = GET_PEDGE(I,J,L) 
!               P2   = GET_PEDGE(I,J,L+1)
!               DELP = P1 - P2
!
!               ! Case of model grid is lower than PBL
!               IF ( BLTOP <= P2 )  THEN
!                  FEMIS = DELP / BLTHIK
!   
!               ! Level L lies completely w/in the PBL
!               ELSE IF ( BLTOP > P2 .AND. BLTOP < P1 ) THEN
!                  FEMIS = ( P1 - BLTOP ) / BLTHIK
!
!               ! Level L lies completely out of the PBL
!               ELSE IF ( BLTOP > P1 ) THEN
!                  CYCLE
!
!               ENDIF
!
!               ! Partition total seasalt into level K [kg/ts]
!               ! This is just for error checking
!               SALTSRC   = SALTSRC   + ( FEMIS * SALT(I,J) )
!
!               ! Fraction of total seasalt in level L
!               TC(I,J,L) = TC(I,J,L) + ( FEMIS * SALT(I,J) )
!            ENDDO
!
!            ! Error check
!            IF ( ABS( SALTSRC - SALT(I,J) ) > 1.D-5 ) THEN
!!$OMP CRITICAL
!               PRINT*, '### ERROR in SRCSALT!'
!               PRINT*, '### I, J           : ', I, J
!               PRINT*, '### SALTSRC        : ', SALTSRC
!               PRINT*, '### SRCE_SEAS(I,J) : ', SALT(I,J)
!!$OMP END CRITICAL
!               CALL ERROR_STOP( 'Check SEASALT redistribution', 
!     &                          'SRCSALT (seasalt_mod.f)' )
!            ENDIF
!
!         !==============================================================
!         ! If PBL height and lower or similar to the second model layer
!         ! then surface emission is emitted to the first model layer	
!         !==============================================================
!         ELSE         
!            TC(I,J,1) = TC(I,J,1) + SALT(I,J)
!         ENDIF 
!-----------------------------------------------------------------------------

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, NTOP, L, FEMIS )
!$OMP+SCHEDULE( DYNAMIC ) 
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         ! Layer in which the PBL top occurs
         NTOP = CEILING( GET_PBL_TOP_L( I, J ) )
        
         ! Loop thru the boundary layer
         DO L = 1, NTOP

            ! Fraction of the PBL spanned by box (I,J,L) [unitless]
            FEMIS     = GET_FRAC_OF_PBL( I, J, L )

            ! Add seasalt emissions into box (I,J,L) [kg]
            TC(I,J,L) = TC(I,J,L) + ( FEMIS * SALT(I,J) )

         ENDDO

         ! ND08 diagnostic: sea salt emissions [kg]
         IF ( ND08 > 0 ) THEN
            AD08(I,J,N) = AD08(I,J,N) + SALT(I,J)
         ENDIF
      ENDDO
      ENDDO
!$OMP END PARALLEL DO  

      ! Return to calling program
      END SUBROUTINE SRCSALT

!------------------------------------------------------------------------------

      SUBROUTINE INIT_SEASALT
!
!******************************************************************************
!  Subroutine INIT_SEASALT initializes all module arrays (bmy, 4/26/04)
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD, ONLY : ALLOC_ERR

      ! Local variables
      INTEGER :: AS

      !=================================================================
      ! INIT_SEASALT begins here!
      !=================================================================
      ALLOCATE( REDGE( 0:NR_MAX, NSALT ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'REDGE' )
      REDGE = 0d0

      ALLOCATE( RMID( NR_MAX, NSALT ), STAT=AS )
      IF ( AS /=0 ) CALL ALLOC_ERR( 'RMID' )
      RMID = 0d0

      ALLOCATE( SRC( NR_MAX, NSALT ), STAT=AS )
      IF ( AS /=0 ) CALL ALLOC_ERR( 'SRC' )
      SRC = 0d0

      ! Return to calling program
      END SUBROUTINE INIT_SEASALT

!----------------------------------------------------------------------------

      SUBROUTINE CLEANUP_SEASALT
!
!******************************************************************************
!  Subroutine INIT_SEASALT deallocates all module arrays (bmy, 4/26/04)
!
!  NOTES:
!******************************************************************************
!
      !=================================================================
      ! CLEANUP_SEASALT begins here!
      !=================================================================
      IF ( ALLOCATED( REDGE ) ) DEALLOCATE( REDGE )
      IF ( ALLOCATED( RMID  ) ) DEALLOCATE( RMID  )
      IF ( ALLOCATED( SRC   ) ) DEALLOCATE( SRC   )
      
      ! Return to calling program
      END SUBROUTINE CLEANUP_SEASALT

!------------------------------------------------------------------------------

      END MODULE SEASALT_MOD