#!/bin/sh

#@ error= $(job_name).e$(jobid)
#@ job_type=parallel
#@ class=dev
#@ group=dev
#@ account_no = RDAS-MTN

#
#  test nems nmmb regional option for gsi
#
#@ job_name=nems_nmmb_gsi
#@ network.MPI=sn_all,shared,us
#@ node = 2
#@ node_usage=not_shared
#@ tasks_per_node=32
#@ task_affinity = core(1)
#@ node_resources = ConsumableMemory(110GB)
#@ wall_clock_limit = 0:15:00
#@ notification=error
#@ restart=no
#@ queue

. regression_var.sh

set -x

# Set environment variables for NCEP IBM
export MP_SHARED_MEMORY=yes
export MEMORY_AFFINITY=MCM
export MP_PULSE=0

# Set environment variables for threads
export AIXTHREAD_GUARDPAGES=4
export AIXTHREAD_MUTEX_DEBUG=OFF
export AIXTHREAD_RWLOCK_DEBUG=OFF
export AIXTHREAD_COND_DEBUG=OFF
export AIXTHREAD_MNRATIO=1:1
export AIXTHREAD_SCOPE=S
export XLSMPOPTS="parthds=1:stack=128000000"

# Set environment variables for user preferences
export XLFRTEOPTS="nlwidth=80"
export MP_LABELIO=yes

# Variables for debugging (don't always need)
##export XLFRTEOPTS="buffering=disable_all"
##export MP_COREFILE_FORMAT=lite

# Set analysis date
adate=$adate_regional_nems_nmmb

# Set experiment name
exp=$exp1_nems_nmmb_bench_2node

# Set path/file for gsi executable
gsiexec=$benchmark

# Set resoltion and other dependent parameters
export JCAP=62
export LEVS=60
export JCAP_B=62
export LEVS=60
export DELTIM=1200

# Set runtime and save directories
tmpdir=$ptmp_loc/tmpreg_${nems_nmmb}/${exp}
savdir=$ptmp_loc/outreg/${nems_nmmb}/${exp}

# Set variables used in script
#   CLEAN up $tmpdir when finished (YES=remove, NO=leave alone)
#   ndate is a date manipulation utility
#   ncp is cp replacement, currently keep as /bin/cp

CLEAN=NO
ndate=/nwprod/util/exec/ndate
ncp=/bin/cp

## Given the analysis date, compute the date from which the
## first guess comes.  Extract cycle and set prefix and suffix
## for guess and observation data files
#sdate=`echo $adate |cut -c1-8`
#odate=`$ndate +12 $adate`
#hha=`echo $adate | cut -c9-10`
#hho=`echo $odate | cut -c9-10`
#prefixo=ndas.t${hho}z
#prefixa=ndas.t${hha}z
###suffix=tm00.bufr_d
#suffix=tm12.bufr_d

datobs=$datobs_nems_nmmb
datges=$datobs

# Set up $tmpdir
rm -rf $tmpdir
mkdir -p $tmpdir
chgrp rstprod $tmpdir
chmod 750 $tmpdir
cd $tmpdir
rm -rf core*

# Make gsi namelist
. $scripts/regression_namelists.sh
cat << EOF > gsiparm.anl

$nems_nmmb_namelist

EOF

anavinfo=$fix_file/anavinfo_nems_nmmb
berror=$fix_file/nam_glb_berror.f77.gcv
emiscoef=$crtm_coef/EmisCoeff/Big_Endian/EmisCoeff.bin
aercoef=$crtm_coef/AerosolCoeff/Big_Endian/AerosolCoeff.bin
cldcoef=$crtm_coef/CloudCoeff/Big_Endian/CloudCoeff.bin
satinfo=$fix_file/nam_regional_satinfo.txt
satangl=$fix_file/nam_global_satangbias.txt
pcpinfo=$fix_file/nam_global_pcpinfo.txt
ozinfo=$fix_file/nam_global_ozinfo.txt
errtable=$fix_file/nam_errtable.r3dv
convinfo=$fix_file/nam_regional_convinfo.txt
mesonetuselist=$fix_file/nam_mesonet_uselist.txt

# Copy executable and fixed files to $tmpdir
$ncp $gsiexec ./gsi.x

$ncp $anavinfo ./anavinfo
$ncp $berror   ./berror_stats
$ncp $emiscoef ./EmisCoeff.bin
$ncp $aercoef  ./AerosolCoeff.bin
$ncp $cldcoef  ./CloudCoeff.bin
$ncp $satangl  ./satbias_angle
$ncp $satinfo  ./satinfo
$ncp $pcpinfo  ./pcpinfo
$ncp $ozinfo   ./ozinfo
$ncp $convinfo ./convinfo
$ncp $errtable ./errtable
$ncp $mesonetuselist ./mesonetuselist

# Copy CRTM coefficient files based on entries in satinfo file
nsatsen=`cat $satinfo | wc -l`
isatsen=1
while [[ $isatsen -le $nsatsen ]]; do
   flag=`head -n $isatsen $satinfo | tail -1 | cut -c1-1`
   if [[ "$flag" != "!" ]]; then
      satsen=`head -n $isatsen $satinfo | tail -1 | cut -f 2 -d" "`
      spccoeff=${satsen}.SpcCoeff.bin
      if  [[ ! -s $spccoeff ]]; then
         $ncp $crtm_coef/SpcCoeff/Big_Endian/$spccoeff ./
         $ncp $crtm_coef/TauCoeff/Big_Endian/${satsen}.TauCoeff.bin ./
      fi
   fi
   isatsen=` expr $isatsen + 1 `
done

# Copy observational data to $tmpdir
$ncp $datobs/ndas.t12z.prepbufr.tm12      ./prepbufr
$ncp $datobs/ndas.t12z.1bhrs3.tm12.bufr_d ./hirs3bufr
$ncp $datobs/ndas.t12z.1bhrs4.tm12.bufr_d ./hirs4bufr
$ncp $datobs/ndas.t12z.1bamua.tm12.bufr_d ./amsuabufr
$ncp $datobs/ndas.t12z.1bamub.tm12.bufr_d ./amsubbufr
$ncp $datobs/ndas.t12z.1bmhs.tm12.bufr_d  ./mhsbufr
$ncp $datobs/ndas.t12z.goesfv.tm12.bufr_d ./gsnd1bufr
$ncp $datobs/ndas.t12z.airsev.tm12.bufr_d ./airsbufr
$ncp $datobs/ndas.t12z.radwnd.tm12.bufr_d ./radarbufr

# Copy bias correction, sigma, and surface files
#
#  *** NOTE:  The regional gsi analysis is written to (over)
#             the input guess field file (wrf_inout)
#
$ncp $datges/ndas.t06z.satang.tm09 ./satbias_angle
$ncp $datges/ndas.t06z.satbias.tm09 ./satbias_in

$ncp $datges/nmm_b_history_nemsio.012 wrf_inout
$ncp $datges/nmm_b_history_nemsio.012.ctl wrf_inout.ctl
$ncp wrf_inout wrf_ges
$ncp wrf_inout.ctl wrf_ges.ctl

# Run gsi under Parallel Operating Environment (poe) on NCEP IBM
poe $tmpdir/gsi.x < gsiparm.anl > stdout
rc=$?

if [[ "$rc" != "0" ]]; then
   cd $regression_vfydir
   {
    echo ''$exp1_nems_nmmb_sub_2node' has failed to run to completion, with an error code of '$rc''
   } >> $nems_nmmb_regression
   $step_name==$rc
   exit
fi

# Save output
mkdir -p $savdir
chgrp rstprod $savdir
chmod 750 $savdir

cat stdout fort.2* > $savdir/stdout.anl.${adate}
$ncp wrf_inout       $savdir/wrfanl.${adate}
$ncp satbias_out     $savdir/biascr.${adate}

# If desired, copy guess file to unique filename in $savdir
$ncp wrf_ges         $savdir/wrfges.${adate}

# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#

cd $tmpdir
loops="01 03"
for loop in $loops; do

case $loop in
  01) string=ges;;
  03) string=anl;;
   *) string=$loop;;
esac

# Collect diagnostic files for obs types (groups) below
   listall="hirs2_n14 msu_n14 sndr_g08 sndr_g10 sndr_g12 sndr_g08_prep sndr_g10_prep sndr_g12_prep sndrd1_g08 sndrd2_g08 sndrd3_g08 sndrd4_g08 sndrd1_g10 sndrd2_g10 sndrd3_g10 sndrd4_g10 sndrd1_g12 sndrd2_g12 sndrd3_g12 sndrd4_g12 sndrd1_g11 sndrd2_g11 sndrd3_g11 sndrd4_g11 sndrd1_g13 sndrd2_g13 sndrd3_g13 sndrd4_g13 hirs3_n15 hirs3_n16 hirs3_n17 amsua_n15 amsua_n16 amsua_n17 amsub_n15 amsub_n16 amsub_n17 hsb_aqua airs_aqua amsua_aqua imgr_g08 imgr_g10 imgr_g12 pcp_ssmi_dmsp
pcp_tmi_trmm conv sbuv2_n16 sbuv2_n17 sbuv2_n18 omi_aura ssmi_f13 ssmi_f14 ssmi_f15 hirs4_n18 amsua_n18 mhs_n18 amsre_low_aqua amsre_mid_aqua amsre_hig_aqua ssmis_las_f16 ssmis_uas_f16 ssmis_img_f16 ssmis_env_f16 iasi_metop-a"
   for type in $listall; do
      count=`ls dir.*/${type}_${loop}* | wc -l`
      if [[ $count -gt 0 ]]; then
         cat dir.*/${type}_${loop}* > diag_${type}_${string}.${adate}
         compress diag_${type}_${string}.${adate}
         $ncp diag_${type}_${string}.${adate}.Z $savdir/
      fi
   done
done

exit
