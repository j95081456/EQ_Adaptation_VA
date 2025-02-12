*** EQ Adaptation ***
.prot
.lib '/home/m111/m111061571/cic018.l' TT 25
.unprot
.option
+ post 
+ captab
+ ABSTOL=1E-7 RELTOT=1E-7 ACCURATE=6 delmax=1E-10
+ sim_mode=hspice

**** parameter ****
.param VCCQ  = 1V
*///// circuit /////*
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/ffe.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/dfe.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/find_h0_v2.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/find_tap1.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/find_tap2.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/CDR/BBPD.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/CDR/PI.va'
.hdl '/home/m111/m111061571/hspice/EQ_Adaptation/vco.va'

*// FFE //*
xffe vin ck_tx vout_ffe ffe

*// h0 & DFE //*
xdfe        vin_rs  ck_pi      tap1       tap2      add_out   decision1 decision2 decision3 DFE
xfind_h0_v2 add_out ck_pi h0   find_h0_v2
xfind_tap1  add_out h0 ck_pi   decision1  decision2 en_tap1   tap1      find_tap1
xfind_tap2  add_out h0 ck_pi   decision1  decision3 en_tap2   tap2      find_tap2

*// CDR //*
 Vthr thr 0 0.5
 xcprt_n   add_out   thr      ck_pi     e01                   comparator_nedge
 xbbpd     decision2 e01      decision1 ck_pi v_code v_ki_acc BBPD
 xpi       ck_rx     v_code   ck_mid   pi
 xpi_first ck_rx     v_first  ck_first pi
 xpi_end   ck_rx     v_end    ck_end   pi
 xpi_add   ck_mid    ck_first ck_end v_code ck_pi pi_add

*///// power & bias /////*
VCCQ  VCCQ   0  VCCQ
VSS   VSS    0  0

*//// input ////*
 Vin      vin      0 LFSR  0 VCCQ  1n 10p 10p 20G 1 [23, 18]
*Vtx_ssc  v_tx_ssc 0 pulse 0   1V  400n 100n 100n 0.1n   200.2n
*Vtx_ssc  v_tx_ssc 0 pulse 0   1V  400n  10u  10u 0.1n 20.0001u
*Vtx_ssc  v_tx_ssc 0 pulse 0 0.5V  400n   1n   1n   1m       2m  
 Vtx_ssc  v_tx_ssc 0 0
 xtx_ck   v_tx_ssc ck_tx VCO_VA2                             *// vctrl, ck_out //* 
 Vck_rx   ck_rx    0 pulse 0 VCCQ   '1n + 43p' 5p 5p 20p 50p
 Ven_tap1 en_tap1  0 pulse 0 VCCQ 100n 10p 10p 400n 4m
 Ven_tap2 en_tap2  0 pulse 0 VCCQ 100n 10p 10p 400n 4m

*//// channel ////*
*Rs vin    vin_rs 50
*CL vin_rs 0      2p
*Rt vin_rs 0      50

Rs vout_ffe n0     50  *// 50 //*
L1 n0       vin_rs 2n  *// 0n //*
C1 vin_rs 0        1p  *// 2p //*
Rt vin_rs 0        50

*.model s_model S TSTONEFILE = "/home/m111/m111061571/hspice/EQ_Adaptation/channel/M8049_003_TRACE7_V2.s2p"
*S1 vin 0 vin_rs 0 mname=s_model
*.model s_model S TSTONEFILE = "/home/m111/m111061571/hspice/EQ_Adaptation/channel/PCIe5_ISI_PAIR38_CBB_CLB_PAIR0_FC_PKG.s4p"
*S1 vin 0 0 0 vin_rs 0 0 0 mname=s_model

*//// debug ////*
*Vtap1 tap1 0 -0.114
*Vh0 h0 0 0.685
*Vck_pi v_code 0 62
 Vck_first v_first 0 20
 Vck_end   v_end   0 69
*--------------measure---------------*

.op
.tr 0.01p 1000n
.probe V(*)
*.probe I(*)

*xdff_edge e01 ck_pi e01_align n1_edge DFF_dfe
*xbbpd     decision2 e01_align decision1 ck_pi v_code BBPD

.end

*hspice -mt 8 -i 1.sp -o 1.lis

*.option numdgt=6 measdgt=6 *// number of digits //*
* runlvl=1 *// 1 to 6, fastest to most accurate
*// trap(trapezoidal): more accurate & fast, but worse  convergency. //*
*// gear             : less accurate & slow, but better convergency. //*
*.option method=gear 
*.option measform=3  *// generate excel file //*
*.temp -40 25 125

*Vin1 Vin  0  sin 0.2 0.05 500X *// dc amp freq //*
*Vpwl Vpwl 0 PWL(0n V1 0.45n V1 0.46n V2 0.85n V2 0.86n V1) 
*Vprbs vin 0 LFSR (vl vh delay trise tfall freq seed [10, 5, 3, 2])
*Eamp n3 n4 VCVS n1 n2 1000 *// gain //*
*Eac n3 n4 n1 n2 1

*// switch //*
*Gsw Vout Vin VCR PWL(1) Vaz 0 0V, 100G 1.8V, 1m *// voltage control resistance//*
*Vaz Vaz 0 pulse (0 1.8 1u 10n 10n 1u 1m)

*.dc Vdc 1.8 0 0.0001 
*.ac dec 10 1 100G
*.tr 0.1p 1n
*sweep wp lin 10 1u 10u
*// mc: monte carlo, fmin: control flicker noise source, fmax:highest freq noise, scale: amplify factor //*
*.trannoise method=mc samples=1000 fmin=1 fmax=100e9 scale=1 


*.meas ac DC_gain  FIND Vdb(vout) at=1
*.meas ac DC_gain0 FIND Vdb(VON0,VOP0) at=1
*.meas ac W_unit WHEN Vdb(vout)=0 
*.meas tr Var3 param='Var1 - Var2'
*.meas tr Var1 trig V(vout)='VDD/2' rise=1 targ V(vout)='VDD/2' fall=1
*.meas tr Iin AVG I(vin) from=500n to=1u
*.meas tr Iin AVG abs('I(vin)') from=1u to=3u

*.probe I(x0.*)
*.probe gm1=lx7(x2.MSF)
*.probe gmb1=lx9(x2.MSF)
*.probe vth1=lv9(x2.MSF)
*.probe vth2=Vth(x2.MSF)
*.probe gds=LX8(Mtest3)
*.probe Vgs=lx2(Mtest3)
*.probe Gain2=deriv('V(Vout2)')
*.probe Vdiff0=par('V(VON0)-V(VOP0)')
*.probe Cxx = Cap(nodexx)
