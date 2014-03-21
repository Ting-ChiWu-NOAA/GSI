;---------------------------------------------------------------------------------
; Name:  plotRad.pro
;
; Type:  IDL Program
;
; Description:
;   A local procedure used by main-level assessment tool code
;   to plot both observed radiance and simulated radiance.
;
; Author: Deyong Xu (RTI) @ JCSDA,
;         Deyong.Xu@noaa.gov
; Version: Mar 5, 2014, DXu, Initial coding
;
;
;---------------------------------------------------------------------------------
PRO plotRad, chPlotArray, chanNumArray, chanInfoArray, prefix,       $
    MIN_LAT, MAX_LAT, MIN_LON, MAX_LON, minBT_Values, maxBT_Values,  $
    refRadData, date

   ; Set XSIZE and YSIZE for PS.
   xSizeVal=30
   ySizeVal=30

   ; Save graphics in PS
   SET_PLOT, 'PS'

   ; Get num of channels to plot
   numOfChans = N_ELEMENTS(chPlotArray)

   ; Number of channels per page
   PLOT_PER_PAGE = 4

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

   ; Loop thru. channels to plot
   FOR iChan=0, numOfChans - 1 DO BEGIN
      ; Start a new page every PLOT_PER_PAGE(8) channels.
      rowPosition = iChan MOD PLOT_PER_PAGE
      IF ( rowPosition eq 0 ) THEN BEGIN
         imageName = STRCOMPRESS(prefix + fileNumArray(fileIndex) + '.ps',/remove_all)
         ; Get the file number for the next graphics file
         fileIndex = fileIndex + 1
         ;DEVICE, /CLOSE
         ;ERASE
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
      title = 'SSMIS observed TB ' + channel + date

      ;-----------------
      ; Define filter
      ;-----------------
      ;    radiance: ref_Tb1 > 0.
      ;    Orbit mode flag: ref_ModeFlag1 = 0
      filter1 = WHERE(refRadData.ref_Lat1 ge MIN_LAT       $
		and refRadData.ref_Lat1 le MAX_LAT         $
		and refRadData.ref_Tb1(*,chPlotArray(iChan)) gt 0 $
		and refRadData.ref_ModeFlag1 eq 0)

      ; Generate plot position
      ; Column position
      colPosition = 0

      radPloting, MIN_LAT,MAX_LAT,MIN_LON,MAX_LON,   $
	       refRadData.ref_Lat1,refRadData.ref_Lon1,                  $
	       filter1,   $
	       title,     $
	       minBT_Values(chPlotArray(iChan)),   $
	       maxBT_Values(chPlotArray(iChan)),   $
	       refRadData.ref_Tb1(*,chPlotArray(iChan)),         $
	       'K', $   ;unit
	       0.8, $   ;scale
	       8,   $   ;symb
	       1,   $   ;thick
	       '(f5.1)', $ ;fmt
               rowPosition, colPosition
      
      ;-------------------------------------------------
      ; step 2:
      ;   Plot simulated radiances for chosen channels.
      ;-------------------------------------------------
      channel = chanInfoArray[chPlotArray(iChan)] + ' GHz '
      title = 'SSMIS simulated TB ' + channel + date

      ;-----------------
      ; Define filter
      ;-----------------
      ;    radiance: ref_Tb2 > 0.
      ;    Orbit mode flag: ref_ModeFlag2 = 0
      filter2 = WHERE(refRadData.ref_Lat2 ge MIN_LAT          $
		and refRadData.ref_Lat2 le MAX_LAT            $
		and refRadData.ref_Tb2(*,chPlotArray(iChan)) gt 0 $
		and refRadData.ref_ModeFlag2 eq 0)

      ; Column position
      colPosition = 1

      radPloting, MIN_LAT,MAX_LAT,MIN_LON,MAX_LON,    $
	       refRadData.ref_Lat2,refRadData.ref_Lon2,                  $
	       filter2,   $
	       title,     $
	       minBT_Values(chPlotArray(iChan)),      $
	       maxBT_Values(chPlotArray(iChan)),      $
	       refRadData.ref_Tb2(*,chPlotArray(iChan)),         $
	       'K', $   ;unit
	       0.8, $   ;scale
	       8,   $   ;symb
	       1,   $   ;thick
	       '(f5.1)', $ ;fmt
               rowPosition, colPosition

      ;-------------------------------------------------
      ; step 3:
      ;   Plot radiance difference 
      ;-------------------------------------------------
      ;-----------------
      ; Define filter
      ;-----------------
      ;    radiance: ref_Tb1 > 0.
      ;    radiance: ref_Tb2 > 0.
      ;    Orbit mode flag: ref_ModeFlag1 = 0
      ;    Orbit mode flag: ref_ModeFlag2 = 0
      filter3 = WHERE(refRadData.ref_Lat1 ge MIN_LAT               $
                and refRadData.ref_Lat1 le MAX_LAT                $
                and refRadData.ref_Tb1(*,chPlotArray(iChan)) gt 0 $
                and refRadData.ref_ModeFlag1 eq 0                 $
                and refRadData.ref_Lat2 ge MIN_LAT                $
                and refRadData.ref_Lat2 le MAX_LAT                $
                and refRadData.ref_Tb2(*,chPlotArray(iChan)) gt 0 $
                and refRadData.ref_ModeFlag2 eq 0)

      ; Generate ref_TbDiff based on filter
      refRadData.ref_TbDiff(filter3, chPlotArray(iChan))  =    $
            refRadData.ref_Tb1(filter3, chPlotArray(iChan) )   $
            - refRadData.ref_Tb2(filter3, chPlotArray(iChan) )

      ; Column position
      colPosition = 2

      ; Get min and max of radiance differences for each channel. 
      minTB_DiffValue = min(refRadData.ref_TbDiff(filter3, chPlotArray(iChan)))
      maxTB_DiffValue = max(refRadData.ref_TbDiff(filter3, chPlotArray(iChan)))

      radPloting, MIN_LAT,MAX_LAT,MIN_LON,MAX_LON,    $
               refRadData.ref_Lat1,refRadData.ref_Lon1,    $
               filter3,   $
               title,     $
               minTB_DiffValue,    $
               maxTB_DiffValue,    $
               refRadData.ref_TbDiff(*, chPlotArray(iChan)), $
               'K', $   ;unit
               0.8, $   ;scale
               8,   $   ;symb
               1,   $   ;thick
               '(f5.1)', $ ;fmt
               rowPosition, colPosition

      ; Close 'PS' file every PLOT_PER_PAGE (4)
      IF (rowPosition EQ PLOT_PER_PAGE - 1 ||   $
          iChan eq numOfChans - 1 ) THEN DEVICE, /CLOSE

   ENDFOR

END

;======================================================

PRO radPloting, MIN_LAT, MAX_LAT, MIN_LON, MAX_LON,   $
    latVect, lonVect, filter, title,                  $
    minValue, maxValue, data, unit, scal,             $ 
    symb, thickVal, fmt, rowPosition, colPosition

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
   xOrigin = 0.02
   yOrigin = 0.07

   ; plot width
   plotWidth = 0.31
   ; plot height
   plotHeight = 0.16
   ; color bar height
   barHeight = 0.025

   xSpacer = 0.02  ; space between two plots horizontally.
   ySpacer = 0.03  ; space between bar and next plot vertically.
   innerSpacer = 0.01    ; space between plot and bar vertically.

   plotY_Pos = findgen(4) ; array holding box position
   barY_Pos = findgen(4) ; array holding bar position

   ; Define y positions of boxes and bars
   FOR i=0, 3 DO BEGIN
      ; box's y positions
      plotY_Pos(i) = yOrigin + barHeight + innerSpacer    $
	      + ( 3 - i ) * (plotHeight + innerSpacer + barHeight + ySpacer )
      ; bar's y positions
      barY_Pos(i) = yOrigin + ( 3 - i )     $
              * (plotHeight + innerSpacer + barHeight + ySpacer )
   ENDFOR

   ; Define box's position
   IF ( colPosition eq 0 ) THEN BEGIN             ; left
      x0 = xOrigin
      y0 = plotY_Pos ( rowPosition )
      x1 = xOrigin + plotWidth
      y1 = plotY_Pos ( rowPosition ) + plotHeight
   ENDIF ELSE IF ( colPosition eq 1 ) THEN BEGIN  ; middle
      x0 = xOrigin + ( plotWidth + xSpacer )
      y0 = plotY_Pos ( rowPosition )
      x1 = xOrigin + ( plotWidth + xSpacer ) + plotWidth
      y1 = plotY_Pos ( rowPosition ) + plotHeight
   ENDIF ELSE BEGIN                               ; right
      x0 = xOrigin + 2 * ( plotWidth + xSpacer )
      y0 = plotY_Pos ( rowPosition )
      x1 = xOrigin + 2 * ( plotWidth + xSpacer ) + plotWidth
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

   FOR iProf=0L,nRec-1 DO BEGIN
      ; Get index value
      index = filter(iProf)
      ; Get data value
      dataVal=data[index]
      colorVal=0L
      colorNum=(float(dataVal-minValue)/float(maxValue-minValue))*nColor
      ;dxu colorVal=long(colorNum) > 1L < nColor
      ;colorVal=long(colorNum) > 1L < nColor
      colorVal=long(colorNum)

      OPLOT,[lonVect[index]],[latVect[index]],color=colorVal-1,psym=symb,$
         symsize=scal,thick=thickVal

   ENDFOR

   IF ((maxValue-minValue) gt 0.) THEN BEGIN
      ; Define the position of color bar
      IF ( colPosition eq 0 ) THEN BEGIN 
	 x0 = xOrigin
	 y0 = barY_Pos ( rowPosition )
	 x1 = xOrigin + plotWidth
	 y1 = barY_Pos ( rowPosition ) + barHeight
      ENDIF ELSE IF ( colPosition eq 1 ) THEN BEGIN
	 x0 = xOrigin + ( plotWidth + xSpacer ) 
	 y0 = barY_Pos ( rowPosition )
	 x1 = xOrigin + ( plotWidth + xSpacer ) + plotWidth
	 y1 = barY_Pos ( rowPosition ) + barHeight
      ENDIF ELSE BEGIN
	 x0 = xOrigin + 2 * ( plotWidth + xSpacer )
	 y0 = barY_Pos ( rowPosition )
	 x1 = xOrigin + 2 * ( plotWidth + xSpacer ) + plotWidth
	 y1 = barY_Pos ( rowPosition ) + barHeight
      ENDELSE 

      COLORBAR,NCOLORS=nColor,/HORIZONTAL,RANGE=[minValue,maxValue],TITLE=unit,$
	  FORMAT=fmt,CHARSIZE=charSize*1.3,FONT=1,POSITION=[x0, y0, x1, y1]
   ENDIF ELSE BEGIN
       PRINT, 'Warning: in radPloting: No color bar plotted: (maxValue-minValue) <= 0.'
   ENDELSE
END
