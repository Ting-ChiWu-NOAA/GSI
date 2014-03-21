;---------------------------------------------------------------------------------
; Name:  plotRaDiff.pro
;
; Type:  IDL Program
;
; Description:
;   A local procedure used by main-level assessment tool code
;   to plot radiance bias per channel
;   radiance.
;
; Author: Deyong Xu (RTI) @ JCSDA,
;         Deyong.Xu@noaa.gov
; Version: Mar 12, 2014, DXu, Initial coding
;
;
;---------------------------------------------------------------------------------
PRO plotRadDiff, chPlotArray, chanNumArray, chanInfoArray, prefix, $
    MIN_LAT, MAX_LAT, MIN_LON, MAX_LON, $
    refRadData, nChan, date

   ; Set XSIZE and YSIZE for PS.
   xSizeVal=18
   ySizeVal=30

   ; Save graphics in PS
   SET_PLOT, 'PS'

   ; Get num of channels to plot
   numOfChans = N_ELEMENTS(chPlotArray)

   ; Number of channels per page
   PLOT_PER_PAGE = 8 

   ; Total number of graphics files
   IF ((numOfChans MOD PLOT_PER_PAGE) eq 0 ) THEN BEGIN 
      nFiles = numOfChans / PLOT_PER_PAGE
   ENDIF ELSE BEGIN 
      nFiles = numOfChans / PLOT_PER_PAGE + 1
   ENDELSE
   ; Create string array with an extra element, so we 
   ; can refer to it as 1-base string array.
   fileNumArray = SINDGEN(nFiles+1)
   ; Graphics file number tracking: 1-base
   fileIndex = 1
  
   ;######################################################
   ; 1. Plot radiance difference
   ;######################################################
   ; Loop thru. channels
   FOR iChan = 0, numOfChans - 1 DO BEGIN
      ; Start a new page every PLOT_PER_PAGE(8) channels. 
      filePosition = iChan MOD PLOT_PER_PAGE
      IF ( filePosition eq 0 ) THEN BEGIN
         imageName = STRCOMPRESS(prefix + fileNumArray(fileIndex) + '.ps',/remove_all)
         ; Get the file number for the next graphics file
         fileIndex = fileIndex + 1 
         ERASE
         LOADCT, 39
         !P.FONT=-1
         DEVICE, FILENAME=imageName, /COLOR, BITS_PER_PIXEL=8,          $
                 XSIZE=xSizeVal, YSIZE=ySizeVal, XOFFSET=2, YOFFSET=2,  $
                 /PORTRAIT, FONT_SIZE=7, /BOLD, /COURIER
      ENDIF

      ;------------------------------------------------
      ; step 1:
      ;   Plot observed radiances for chosen channels.
      ;------------------------------------------------
      channel = chanInfoArray[chPlotArray(iChan)] + ' GHz '
      title = 'SSMIS TB Diff ' + channel + date

      ;-----------------
      ; Define filter
      ;-----------------
      ;    radiance: ref_Tb1 > 0.
      ;    radiance: ref_Tb2 > 0.
      ;    Orbit mode flag: ref_ModeFlag1 = 0
      ;    Orbit mode flag: ref_ModeFlag2 = 0
      filter = WHERE(refRadData.ref_Lat1 ge MIN_LAT               $
		and refRadData.ref_Lat1 le MAX_LAT                $
		and refRadData.ref_Tb1(*,chPlotArray(iChan)) gt 0 $
		and refRadData.ref_ModeFlag1 eq 0                 $
		and refRadData.ref_Lat2 ge MIN_LAT                $
		and refRadData.ref_Lat2 le MAX_LAT                $
		and refRadData.ref_Tb2(*,chPlotArray(iChan)) gt 0 $
		and refRadData.ref_ModeFlag2 eq 0)

      ; Generate ref_TbDiff based on filter
      refRadData.ref_TbDiff(filter, chPlotArray(iChan))  =    $
            refRadData.ref_Tb1(filter, chPlotArray(iChan) )   $
            - refRadData.ref_Tb2(filter, chPlotArray(iChan) )
      ; Generate plot position
      ; Row position
      rowPosition = ( iChan MOD PLOT_PER_PAGE )/ 2
      ; 0-base index iChan:
      ;   0, 2, 4, ... drawn on left
      ;   1, 3, 5, ... drawn on right
      ; Default column position is on right 
      colPosition = 1
      IF ( (iChan MOD 2) eq 0 ) THEN BEGIN
         colPosition = 0
      ENDIF

      tbDiffPlotting, MIN_LAT,MAX_LAT,MIN_LON,MAX_LON,$
	       refRadData.ref_Lat1,refRadData.ref_Lon1,                  $
	       filter,                             $
	       title,                              $
	       refRadData.ref_TbDiff(*,chPlotArray(iChan)),         $
	       'K', $   ;unit
	       0.8, $   ;scale
	       8,   $   ;symb
	       1,   $   ;thick
	       '(f5.1)', $ ;fmt
               rowPosition, colPosition
   ENDFOR

END

;======================================================

PRO tbDiffPlotting,MIN_LAT,MAX_LAT,MIN_LON,MAX_LON,   $
    ref_Lat1,ref_Lon1,filter,title,              $
    ref_TbDiff,unit,scal,  $ 
    symb,thickVal,fmt, rowPosition, colPosition

   ; Get min and max of bias. 
   minTB_DiffValue = min(ref_TbDiff)
   maxTB_DiffValue = max(ref_TbDiff)

   ; set the default charsz
   charSize=1.
   nRec=n_elements(filter)
   
   ; num of colos 
   nColor=!D.table_size
   nColor=nColor-2

   csize=16
   ; Divide 2.5PI by 16.
   tmpVal = findgen(csize+1) * (!PI*2.5/float(csize))
   usersym,scal*cos(tmpVal)/2,scal*sin(tmpVal)/2,/fill

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   center_lon=0
   latdelVal=max([fix((MAX_LAT-MIN_LAT)/100),1])*30
   londelVal=max([fix((MAX_LON-MIN_LON)/100),1])*20

   ; Define where plots start
   yOrgin=0.07
   xOrgin=0.05

   ; plot width
   plotWidth = 0.42
   ; plot height
   plotHeight = 0.16
   ; color bar height
   barHeight = 0.025

   xSpacer=0.03      ; space between two plots horizontally.
   ySpacer=0.03      ; space between bar and next plot vertically.
   innerSpacer=0.01  ; space between plot and bar vertically.

   plotY_Pos = findgen(4) ; array holding box position
   barY_Pos = findgen(4) ; array holding bar position

   ; Define y positions of boxes and bars
   FOR i=0, 3 DO BEGIN
      ; box's y positions
      plotY_Pos(i) = yOrgin + barHeight + innerSpacer    $
	      + ( 3 - i ) * (plotHeight + innerSpacer + barHeight + ySpacer )
      ; bar's y positions
      barY_Pos(i) = yOrgin + ( 3 - i )     $
              * (plotHeight + innerSpacer + barHeight + ySpacer )
   ENDFOR

   ; Define box's position
   IF ( colPosition eq 0 ) THEN BEGIN 
      x0 = xOrgin
      y0 = plotY_Pos ( rowPosition )
      x1 = xOrgin + plotWidth
      y1 = plotY_Pos ( rowPosition ) + plotHeight
   ENDIF ELSE BEGIN 
      x0 = xOrgin + plotWidth + xSPacer
      y0 = plotY_Pos ( rowPosition )
      x1 = xOrgin + 2 * ( plotWidth + xSPacer )
      y1 = plotY_Pos ( rowPosition ) + plotHeight
   ENDELSE 

   MAP_SET,0,CENTER_LON,XMARGIN=[8,8],YMARGIN=[8,8], /NOERASE,  $
      LIMIT=[MIN_LAT,MIN_LON,MAX_LAT,MAX_LON],/HIRES,TITLE=title,$
      POSITION=[x0,y0,x1,y1],LATDEL=latdelVal,LONDEL=londelVal,/grid,$

   charsize=charSize*1.3

   MAP_CONTINENTS,/CONTINENTS,/NOBORDER,/HIRES,/USA,FILL_CONTINENTS=0,COLOR=18

   MAP_GRID,LATDEL=latdelVal,LONDEL=londelVal,/LABEL,          $
      LONLAB=MIN_LAT,LATLAB=MIN_LON,LONALIGN=0.,LATALIGN=0.,   $
      CHARSIZE=charSize*1.3

   FOR iprof=0L,nRec-1 DO BEGIN
      ; index value
      index = filter(iprof)
      ; BT value
      tbDiffVal=ref_TbDiff[index]
      colorVal=0L
      colorNum=(float(tbDiffVal-minTB_DiffValue)/float(maxTB_DiffValue-minTB_DiffValue))*nColor
      colorVal=long(colorNum)

      OPLOT,[ref_Lon1[index]],[ref_Lat1[index]],color=colorVal-1,psym=symb,$
         symsize=scal,thick=thickVal

   ENDFOR

   IF ((maxTB_DiffValue-minTB_DiffValue) gt 0.) THEN BEGIN
      ; Define the position of color bar
      IF ( colPosition eq 0 ) THEN BEGIN 
	 x0 = xOrgin
	 y0 = barY_Pos ( rowPosition )
	 x1 = xOrgin + plotWidth
	 y1 = barY_Pos ( rowPosition ) + barHeight
      ENDIF ELSE BEGIN
	 x0 = xOrgin + plotWidth + xSPacer
	 y0 = barY_Pos ( rowPosition )
	 x1 = xOrgin + 2 * ( plotWidth + xSPacer )
	 y1 = barY_Pos ( rowPosition ) + barHeight
      END

      COLORBAR,NCOLORS=nColor,/HORIZONTAL,RANGE=[minTB_DiffValue,maxTB_DiffValue],TITLE=unit,$
	  FORMAT=fmt,CHARSIZE=charSize*1.3,FONT=1,POSITION=[x0, y0, x1, y1]
   ENDIF ELSE BEGIN
       PRINT, 'Warning: in radPloting: No color bar plotted: (maxTB_DiffValue-minTB_DiffValue) <= 0.'
   ENDELSE
END
