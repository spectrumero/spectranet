VERSION 6
BEGIN SCHEMATIC
    BEGIN ATTR DeviceFamilyName "xc9500"
        DELETE all:0
        EDITNAME all:0
        EDITTRAIT all:0
    END ATTR
    BEGIN NETLIST
        SIGNAL M1_L
        SIGNAL XLXN_53
        SIGNAL A15
        SIGNAL A14
        SIGNAL A13
        SIGNAL A12
        SIGNAL A11
        SIGNAL A10
        SIGNAL A9
        SIGNAL A8
        SIGNAL HLDROMCS
        SIGNAL XLXN_110
        SIGNAL PAGEOUT
        SIGNAL MREQ_L
        SIGNAL XLXN_114
        SIGNAL XLXN_116
        SIGNAL XLXN_118
        SIGNAL IORQ
        SIGNAL A15OUT
        SIGNAL XLXN_31
        SIGNAL A7
        SIGNAL A6
        SIGNAL A5
        SIGNAL A4
        SIGNAL A3
        SIGNAL A2
        SIGNAL XLXN_84
        SIGNAL XLXN_85
        SIGNAL A1
        SIGNAL A0
        SIGNAL XLXN_182
        SIGNAL EVENT_L
        SIGNAL EXECZERO
        SIGNAL XLXN_207
        SIGNAL XLXN_208
        SIGNAL XLXN_209
        SIGNAL XLXN_210
        SIGNAL XLXN_211
        SIGNAL EXECNMI
        SIGNAL XLXN_222
        SIGNAL XLXN_223
        SIGNAL XLXN_224
        SIGNAL XLXN_225
        SIGNAL XLXN_226
        SIGNAL XLXN_227
        SIGNAL EXECINT
        SIGNAL XLXN_232
        SIGNAL XLXN_233
        SIGNAL XLXN_234
        SIGNAL RST8EN_L
        SIGNAL XLXN_238
        SIGNAL XLXN_240
        SIGNAL CS_L
        SIGNAL XLXN_52
        SIGNAL XLXN_252
        SIGNAL CLK
        SIGNAL XLXN_257
        SIGNAL XLXN_265
        SIGNAL XLXN_266
        SIGNAL D0
        SIGNAL XLXN_268
        SIGNAL XLXN_269
        SIGNAL D7
        SIGNAL D6
        SIGNAL D5
        SIGNAL D4
        SIGNAL D3
        SIGNAL D2
        SIGNAL D1
        SIGNAL XLXN_279
        SIGNAL XLXN_282
        SIGNAL RD_L
        SIGNAL XLXN_295
        SIGNAL XLXN_298
        SIGNAL XLXN_310
        SIGNAL XLXN_311
        SIGNAL CALLTRAP
        SIGNAL XLXN_285
        SIGNAL XLXN_284
        SIGNAL XLXN_336
        SIGNAL XLXN_337
        SIGNAL XLXN_338
        SIGNAL XLXN_339
        SIGNAL XLXN_344
        SIGNAL RESET_L
        SIGNAL XLXN_346
        SIGNAL XLXN_351
        SIGNAL XLXN_356
        SIGNAL XLXN_357
        SIGNAL XLXN_241
        PORT Input M1_L
        PORT Input A15
        PORT Input A14
        PORT Input A13
        PORT Input A12
        PORT Input A11
        PORT Input A10
        PORT Input A9
        PORT Input A8
        PORT Output HLDROMCS
        PORT Input MREQ_L
        PORT Input IORQ
        PORT Output A15OUT
        PORT Input A7
        PORT Input A6
        PORT Input A5
        PORT Input A4
        PORT Input A3
        PORT Input A2
        PORT Input A1
        PORT Input A0
        PORT Input RST8EN_L
        PORT Output CS_L
        PORT Input CLK
        PORT Input D0
        PORT Input D7
        PORT Input D6
        PORT Input D5
        PORT Input D4
        PORT Input D3
        PORT Input D2
        PORT Input D1
        PORT Input RD_L
        PORT Input RESET_L
        BEGIN BLOCKDEF inv
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -32 64 -32 
            LINE N 224 -32 160 -32 
            LINE N 64 -64 128 -32 
            LINE N 128 -32 64 0 
            LINE N 64 0 64 -64 
            CIRCLE N 128 -48 160 -16 
        END BLOCKDEF
        BEGIN BLOCKDEF and9
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 256 -320 192 -320 
            ARC N 96 -368 192 -272 144 -272 144 -368 
            LINE N 144 -272 64 -272 
            LINE N 64 -368 144 -368 
            LINE N 0 -64 64 -64 
            LINE N 0 -512 64 -512 
            LINE N 0 -448 64 -448 
            LINE N 0 -128 64 -128 
            LINE N 0 -256 64 -256 
            LINE N 0 -192 64 -192 
            LINE N 0 -320 64 -320 
            LINE N 0 -384 64 -384 
            LINE N 0 -576 64 -576 
            LINE N 64 -576 64 -64 
        END BLOCKDEF
        BEGIN BLOCKDEF fdce
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -128 64 -128 
            LINE N 0 -192 64 -192 
            LINE N 0 -32 64 -32 
            LINE N 0 -256 64 -256 
            LINE N 384 -256 320 -256 
            LINE N 64 -112 80 -128 
            LINE N 80 -128 64 -144 
            LINE N 192 -64 192 -32 
            LINE N 192 -32 64 -32 
            RECTANGLE N 64 -320 320 -64 
        END BLOCKDEF
        BEGIN BLOCKDEF and2
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -64 64 -64 
            LINE N 0 -128 64 -128 
            LINE N 256 -96 192 -96 
            ARC N 96 -144 192 -48 144 -48 144 -144 
            LINE N 144 -48 64 -48 
            LINE N 64 -144 144 -144 
            LINE N 64 -48 64 -144 
        END BLOCKDEF
        BEGIN BLOCKDEF or2
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -64 64 -64 
            LINE N 0 -128 64 -128 
            LINE N 256 -96 192 -96 
            ARC N 28 -224 204 -48 112 -48 192 -96 
            ARC N -40 -152 72 -40 48 -48 48 -144 
            LINE N 112 -144 48 -144 
            ARC N 28 -144 204 32 192 -96 112 -144 
            LINE N 112 -48 48 -48 
        END BLOCKDEF
        BEGIN BLOCKDEF ldc
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -128 64 -128 
            LINE N 0 -32 64 -32 
            LINE N 0 -256 64 -256 
            LINE N 384 -256 320 -256 
            RECTANGLE N 64 -320 320 -64 
            LINE N 64 -112 80 -128 
            LINE N 80 -128 64 -144 
            LINE N 192 -64 192 -32 
            LINE N 192 -32 64 -32 
        END BLOCKDEF
        BEGIN BLOCKDEF vcc
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 96 -64 32 -64 
            LINE N 64 0 64 -32 
            LINE N 64 -32 64 -64 
        END BLOCKDEF
        BEGIN BLOCKDEF nor9
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -448 48 -448 
            LINE N 0 -128 48 -128 
            LINE N 0 -192 48 -192 
            LINE N 0 -256 48 -256 
            LINE N 0 -512 48 -512 
            LINE N 0 -576 48 -576 
            ARC N -40 -376 72 -264 48 -272 48 -368 
            LINE N 112 -368 48 -368 
            LINE N 112 -272 48 -272 
            ARC N 28 -368 204 -192 192 -320 112 -368 
            LINE N 48 -576 48 -368 
            LINE N 48 -64 48 -272 
            LINE N 0 -64 48 -64 
            LINE N 0 -384 48 -384 
            LINE N 0 -320 72 -320 
            ARC N 28 -448 204 -272 112 -272 192 -320 
            LINE N 256 -320 216 -320 
            CIRCLE N 192 -332 216 -308 
        END BLOCKDEF
        BEGIN BLOCKDEF and8
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 64 -64 64 -512 
            LINE N 0 -64 64 -64 
            LINE N 0 -128 64 -128 
            LINE N 0 -192 64 -192 
            LINE N 0 -256 64 -256 
            LINE N 0 -320 64 -320 
            LINE N 0 -384 64 -384 
            LINE N 0 -448 64 -448 
            LINE N 0 -512 64 -512 
            LINE N 64 -336 144 -336 
            LINE N 144 -240 64 -240 
            ARC N 96 -336 192 -240 144 -240 144 -336 
            LINE N 256 -288 192 -288 
        END BLOCKDEF
        BEGIN BLOCKDEF or4b1
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -64 28 -64 
            CIRCLE N 28 -72 48 -52 
            LINE N 0 -128 64 -128 
            LINE N 0 -192 64 -192 
            LINE N 256 -160 192 -160 
            ARC N 28 -288 204 -112 112 -112 192 -160 
            ARC N 28 -208 204 -32 192 -160 112 -208 
            LINE N 48 -256 48 -208 
            LINE N 48 -64 48 -112 
            LINE N 112 -112 48 -112 
            LINE N 112 -208 48 -208 
            LINE N 0 -256 48 -256 
            ARC N -32 -216 76 -104 48 -112 48 -208 
        END BLOCKDEF
        BEGIN BLOCKDEF fd
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 64 -112 80 -128 
            LINE N 80 -128 64 -144 
            LINE N 384 -256 320 -256 
            LINE N 0 -256 64 -256 
            LINE N 0 -128 64 -128 
            RECTANGLE N 64 -320 320 -64 
        END BLOCKDEF
        BEGIN BLOCKDEF and6
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -64 64 -64 
            LINE N 0 -128 64 -128 
            LINE N 0 -192 64 -192 
            LINE N 0 -256 64 -256 
            LINE N 0 -320 64 -320 
            LINE N 0 -384 64 -384 
            LINE N 256 -224 192 -224 
            LINE N 64 -272 144 -272 
            LINE N 144 -176 64 -176 
            ARC N 96 -272 192 -176 144 -176 144 -272 
            LINE N 64 -64 64 -384 
        END BLOCKDEF
        BEGIN BLOCKDEF or3
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -64 48 -64 
            LINE N 0 -128 72 -128 
            LINE N 0 -192 48 -192 
            LINE N 256 -128 192 -128 
            ARC N 28 -256 204 -80 112 -80 192 -128 
            ARC N -40 -184 72 -72 48 -80 48 -176 
            LINE N 48 -64 48 -80 
            LINE N 48 -192 48 -176 
            LINE N 112 -80 48 -80 
            ARC N 28 -176 204 0 192 -128 112 -176 
            LINE N 112 -176 48 -176 
        END BLOCKDEF
        BEGIN BLOCKDEF ld
            TIMESTAMP 2000 1 1 10 10 10
            RECTANGLE N 64 -320 320 -64 
            LINE N 384 -256 320 -256 
            LINE N 0 -256 64 -256 
            LINE N 0 -128 64 -128 
        END BLOCKDEF
        BEGIN BLOCKDEF or4
            TIMESTAMP 2000 1 1 10 10 10
            LINE N 0 -64 48 -64 
            LINE N 0 -128 64 -128 
            LINE N 0 -192 64 -192 
            LINE N 0 -256 48 -256 
            LINE N 256 -160 192 -160 
            ARC N 28 -208 204 -32 192 -160 112 -208 
            LINE N 112 -208 48 -208 
            LINE N 112 -112 48 -112 
            LINE N 48 -256 48 -208 
            LINE N 48 -64 48 -112 
            ARC N -40 -216 72 -104 48 -112 48 -208 
            ARC N 28 -288 204 -112 112 -112 192 -160 
        END BLOCKDEF
        BEGIN BLOCK XLXI_54 fdce
            PIN C XLXN_114
            PIN CE XLXN_118
            PIN CLR PAGEOUT
            PIN D XLXN_118
            PIN Q XLXN_110
        END BLOCK
        BEGIN BLOCK XLXI_57 inv
            PIN I MREQ_L
            PIN O XLXN_114
        END BLOCK
        BEGIN BLOCK XLXI_58 and2
            PIN I0 XLXN_118
            PIN I1 IORQ
            PIN O XLXN_116
        END BLOCK
        BEGIN BLOCK XLXI_59 or2
            PIN I0 HLDROMCS
            PIN I1 A15
            PIN O A15OUT
        END BLOCK
        BEGIN BLOCK XLXI_23 inv
            PIN I A7
            PIN O XLXN_31
        END BLOCK
        BEGIN BLOCK XLXI_42 inv
            PIN I A0
            PIN O XLXN_84
        END BLOCK
        BEGIN BLOCK XLXI_43 inv
            PIN I A1
            PIN O XLXN_85
        END BLOCK
        BEGIN BLOCK EVENT ldc
            PIN G PAGEOUT
            PIN CLR XLXN_344
            PIN D XLXN_182
            PIN Q EVENT_L
        END BLOCK
        BEGIN BLOCK XLXI_67 vcc
            PIN P XLXN_182
        END BLOCK
        BEGIN BLOCK XLXI_68 nor9
            PIN I0 EVENT_L
            PIN I1 A0
            PIN I2 A1
            PIN I3 A2
            PIN I4 A3
            PIN I5 A4
            PIN I6 A5
            PIN I7 A6
            PIN I8 A7
            PIN O EXECZERO
        END BLOCK
        BEGIN BLOCK XLXI_72 nor9
            PIN I0 M1_L
            PIN I1 A8
            PIN I2 A9
            PIN I3 A10
            PIN I4 A11
            PIN I5 A12
            PIN I6 A13
            PIN I7 A14
            PIN I8 A15
            PIN O XLXN_53
        END BLOCK
        BEGIN BLOCK XLXI_73 and8
            PIN I0 XLXN_84
            PIN I1 XLXN_85
            PIN I2 A2
            PIN I3 A3
            PIN I4 A4
            PIN I5 A5
            PIN I6 A6
            PIN I7 XLXN_31
            PIN O XLXN_52
        END BLOCK
        BEGIN BLOCK XLXI_74 and9
            PIN I0 XLXN_211
            PIN I1 A1
            PIN I2 A2
            PIN I3 XLXN_210
            PIN I4 XLXN_209
            PIN I5 A5
            PIN I6 A6
            PIN I7 XLXN_208
            PIN I8 XLXN_207
            PIN O EXECNMI
        END BLOCK
        BEGIN BLOCK XLXI_75 inv
            PIN I EVENT_L
            PIN O XLXN_207
        END BLOCK
        BEGIN BLOCK XLXI_76 inv
            PIN I A7
            PIN O XLXN_208
        END BLOCK
        BEGIN BLOCK XLXI_77 inv
            PIN I A4
            PIN O XLXN_209
        END BLOCK
        BEGIN BLOCK XLXI_78 inv
            PIN I A3
            PIN O XLXN_210
        END BLOCK
        BEGIN BLOCK XLXI_79 inv
            PIN I A0
            PIN O XLXN_211
        END BLOCK
        BEGIN BLOCK XLXI_81 and9
            PIN I0 XLXN_222
            PIN I1 XLXN_227
            PIN I2 XLXN_226
            PIN I3 XLXN_225
            PIN I4 A3
            PIN I5 A4
            PIN I6 A5
            PIN I7 XLXN_224
            PIN I8 XLXN_223
            PIN O EXECINT
        END BLOCK
        BEGIN BLOCK XLXI_82 inv
            PIN I EVENT_L
            PIN O XLXN_222
        END BLOCK
        BEGIN BLOCK XLXI_83 inv
            PIN I A7
            PIN O XLXN_223
        END BLOCK
        BEGIN BLOCK XLXI_84 inv
            PIN I A6
            PIN O XLXN_224
        END BLOCK
        BEGIN BLOCK XLXI_85 inv
            PIN I A2
            PIN O XLXN_225
        END BLOCK
        BEGIN BLOCK XLXI_86 inv
            PIN I A1
            PIN O XLXN_226
        END BLOCK
        BEGIN BLOCK XLXI_87 inv
            PIN I A0
            PIN O XLXN_227
        END BLOCK
        BEGIN BLOCK XLXI_89 and2
            PIN I0 EXECZERO
            PIN I1 XLXN_53
            PIN O XLXN_232
        END BLOCK
        BEGIN BLOCK XLXI_90 and2
            PIN I0 EXECINT
            PIN I1 XLXN_53
            PIN O XLXN_234
        END BLOCK
        BEGIN BLOCK XLXI_91 and2
            PIN I0 EXECNMI
            PIN I1 XLXN_53
            PIN O XLXN_233
        END BLOCK
        BEGIN BLOCK XLXI_93 nor9
            PIN I0 A0
            PIN I1 A1
            PIN I2 A2
            PIN I3 XLXN_238
            PIN I4 A4
            PIN I5 A5
            PIN I6 A6
            PIN I7 A7
            PIN I8 RST8EN_L
            PIN O XLXN_240
        END BLOCK
        BEGIN BLOCK XLXI_95 inv
            PIN I A3
            PIN O XLXN_238
        END BLOCK
        BEGIN BLOCK XLXI_96 and2
            PIN I0 XLXN_240
            PIN I1 XLXN_53
            PIN O XLXN_241
        END BLOCK
        BEGIN BLOCK XLXI_101 or4b1
            PIN I0 HLDROMCS
            PIN I1 A15
            PIN I2 A14
            PIN I3 MREQ_L
            PIN O CS_L
        END BLOCK
        BEGIN BLOCK XLXI_102 fd
            PIN C XLXN_357
            PIN D XLXN_252
            PIN Q XLXN_257
        END BLOCK
        BEGIN BLOCK XLXI_103 and2
            PIN I0 XLXN_52
            PIN I1 XLXN_53
            PIN O XLXN_252
        END BLOCK
        BEGIN BLOCK XLXI_105 and2
            PIN I0 XLXN_257
            PIN I1 MREQ_L
            PIN O PAGEOUT
        END BLOCK
        BEGIN BLOCK XLXI_107 and9
            PIN I0 XLXN_269
            PIN I1 D0
            PIN I2 XLXN_268
            PIN I3 D2
            PIN I4 D3
            PIN I5 XLXN_266
            PIN I6 XLXN_265
            PIN I7 D6
            PIN I8 D7
            PIN O XLXN_279
        END BLOCK
        BEGIN BLOCK XLXI_108 inv
            PIN I D5
            PIN O XLXN_265
        END BLOCK
        BEGIN BLOCK XLXI_109 inv
            PIN I D4
            PIN O XLXN_266
        END BLOCK
        BEGIN BLOCK XLXI_111 inv
            PIN I D1
            PIN O XLXN_268
        END BLOCK
        BEGIN BLOCK XLXI_112 inv
            PIN I M1_L
            PIN O XLXN_269
        END BLOCK
        BEGIN BLOCK XLXI_116 fd
            PIN C XLXN_295
            PIN D XLXN_282
            PIN Q XLXN_337
        END BLOCK
        BEGIN BLOCK XLXI_123 or2
            PIN I0 RD_L
            PIN I1 MREQ_L
            PIN O XLXN_295
        END BLOCK
        BEGIN BLOCK XLXI_125 fd
            PIN C XLXN_295
            PIN D XLXN_298
            PIN Q XLXN_339
        END BLOCK
        BEGIN BLOCK XLXI_126 and6
            PIN I0 XLXN_337
            PIN I1 D3
            PIN I2 D4
            PIN I3 D5
            PIN I4 D6
            PIN I5 D7
            PIN O XLXN_336
        END BLOCK
        BEGIN BLOCK XLXI_130 fdce
            PIN C XLXN_295
            PIN CE XLXN_310
            PIN CLR PAGEOUT
            PIN D XLXN_311
            PIN Q CALLTRAP
        END BLOCK
        BEGIN BLOCK XLXI_132 vcc
            PIN P XLXN_311
        END BLOCK
        BEGIN BLOCK XLXI_133 or3
            PIN I0 CALLTRAP
            PIN I1 XLXN_110
            PIN I2 XLXN_116
            PIN O HLDROMCS
        END BLOCK
        BEGIN BLOCK XLXI_120 and9
            PIN I0 XLXN_339
            PIN I1 D0
            PIN I2 D1
            PIN I3 D2
            PIN I4 D3
            PIN I5 D4
            PIN I6 D5
            PIN I7 XLXN_285
            PIN I8 XLXN_284
            PIN O XLXN_338
        END BLOCK
        BEGIN BLOCK XLXI_119 inv
            PIN I D6
            PIN O XLXN_285
        END BLOCK
        BEGIN BLOCK XLXI_118 inv
            PIN I D7
            PIN O XLXN_284
        END BLOCK
        BEGIN BLOCK XLXI_135 inv
            PIN I RESET_L
            PIN O XLXN_344
        END BLOCK
        BEGIN BLOCK XLXI_137 ld
            PIN D XLXN_338
            PIN G CLK
            PIN Q XLXN_310
        END BLOCK
        BEGIN BLOCK XLXI_138 ld
            PIN D XLXN_336
            PIN G CLK
            PIN Q XLXN_298
        END BLOCK
        BEGIN BLOCK XLXI_139 ld
            PIN D XLXN_279
            PIN G XLXN_356
            PIN Q XLXN_282
        END BLOCK
        BEGIN BLOCK XLXI_140 inv
            PIN I CLK
            PIN O XLXN_356
        END BLOCK
        BEGIN BLOCK XLXI_141 inv
            PIN I CLK
            PIN O XLXN_357
        END BLOCK
        BEGIN BLOCK XLXI_142 or4
            PIN I0 XLXN_241
            PIN I1 XLXN_234
            PIN I2 XLXN_233
            PIN I3 XLXN_232
            PIN O XLXN_118
        END BLOCK
    END NETLIST
    BEGIN SHEET 1 3520 2720
        BEGIN BRANCH M1_L
            WIRE 224 672 416 672
            WIRE 416 672 416 1312
            WIRE 416 1312 656 1312
        END BRANCH
        BEGIN BRANCH A15
            WIRE 224 160 288 160
            WIRE 288 160 544 160
            WIRE 544 160 544 800
            WIRE 544 800 656 800
            WIRE 288 48 288 160
            WIRE 288 48 2464 48
            WIRE 2464 48 2464 96
            WIRE 2464 96 2688 96
            WIRE 2464 96 2464 640
            WIRE 2464 640 3088 640
        END BRANCH
        BEGIN BRANCH A14
            WIRE 224 224 304 224
            WIRE 304 224 528 224
            WIRE 528 224 528 864
            WIRE 528 864 656 864
            WIRE 304 16 304 224
            WIRE 304 16 2448 16
            WIRE 2448 16 2448 576
            WIRE 2448 576 3088 576
        END BRANCH
        BEGIN BRANCH A13
            WIRE 224 288 512 288
            WIRE 512 288 512 928
            WIRE 512 928 656 928
        END BRANCH
        BEGIN BRANCH A12
            WIRE 224 352 496 352
            WIRE 496 352 496 992
            WIRE 496 992 656 992
        END BRANCH
        BEGIN BRANCH A11
            WIRE 224 416 480 416
            WIRE 480 416 480 1056
            WIRE 480 1056 656 1056
        END BRANCH
        BEGIN BRANCH A10
            WIRE 224 480 464 480
            WIRE 464 480 464 1120
            WIRE 464 1120 656 1120
        END BRANCH
        BEGIN BRANCH A9
            WIRE 224 544 448 544
            WIRE 448 544 448 1184
            WIRE 448 1184 656 1184
        END BRANCH
        BEGIN BRANCH A8
            WIRE 224 608 432 608
            WIRE 432 608 432 1248
            WIRE 432 1248 656 1248
        END BRANCH
        BEGIN BRANCH HLDROMCS
            WIRE 2608 160 2688 160
            WIRE 2608 160 2608 240
            WIRE 2608 240 2976 240
            WIRE 2976 240 2976 416
            WIRE 2976 416 3296 416
            WIRE 2976 416 2976 704
            WIRE 2976 704 3088 704
            WIRE 2928 416 2976 416
        END BRANCH
        INSTANCE XLXI_54 2032 672 R0
        BEGIN BRANCH XLXN_110
            WIRE 2416 416 2672 416
        END BRANCH
        BEGIN BRANCH PAGEOUT
            WIRE 1936 816 2032 816
            WIRE 2032 816 2080 816
            WIRE 2080 816 2080 1648
            WIRE 2080 1648 2080 2016
            WIRE 2080 2016 2160 2016
            WIRE 2032 640 2032 816
            BEGIN DISPLAY 2080 1656 ATTR Name
                ALIGNMENT SOFT-TVCENTER
            END DISPLAY
        END BRANCH
        BEGIN BRANCH MREQ_L
            WIRE 1504 688 1568 688
            WIRE 1568 688 1632 688
            WIRE 1632 688 2432 688
            WIRE 1568 688 1568 784
            WIRE 1568 784 1680 784
            WIRE 1632 544 1776 544
            WIRE 1632 544 1632 688
            WIRE 2432 512 2432 688
            WIRE 2432 512 3088 512
        END BRANCH
        BEGIN BRANCH XLXN_114
            WIRE 2000 544 2032 544
        END BRANCH
        INSTANCE XLXI_57 1776 576 R0
        INSTANCE XLXI_58 2032 240 R0
        BEGIN BRANCH XLXN_116
            WIRE 2288 144 2480 144
            WIRE 2480 144 2480 352
            WIRE 2480 352 2672 352
        END BRANCH
        BEGIN BRANCH XLXN_118
            WIRE 1632 448 1808 448
            WIRE 1808 448 1856 448
            WIRE 1856 448 1856 480
            WIRE 1856 480 2032 480
            WIRE 1808 176 2032 176
            WIRE 1808 176 1808 448
            WIRE 1856 416 2032 416
            WIRE 1856 416 1856 448
        END BRANCH
        BEGIN BRANCH IORQ
            WIRE 1984 112 2032 112
        END BRANCH
        INSTANCE XLXI_59 2688 224 R0
        BEGIN BRANCH A15OUT
            WIRE 2944 128 3344 128
        END BRANCH
        IOMARKER 224 160 A15 R180 28
        IOMARKER 224 224 A14 R180 28
        IOMARKER 224 288 A13 R180 28
        IOMARKER 224 352 A12 R180 28
        IOMARKER 224 416 A11 R180 28
        IOMARKER 224 480 A10 R180 28
        IOMARKER 224 544 A9 R180 28
        IOMARKER 224 608 A8 R180 28
        BEGIN BRANCH XLXN_31
            WIRE 816 2176 848 2176
        END BRANCH
        INSTANCE XLXI_23 592 2208 R0
        BEGIN BRANCH A7
            WIRE 176 1552 176 1952
            WIRE 176 1952 384 1952
            WIRE 384 1952 384 2176
            WIRE 384 2176 592 2176
            WIRE 176 1552 512 1552
            WIRE 208 2176 384 2176
        END BRANCH
        BEGIN BRANCH A6
            WIRE 192 1616 192 1936
            WIRE 192 1936 400 1936
            WIRE 400 1936 400 2240
            WIRE 400 2240 848 2240
            WIRE 192 1616 512 1616
            WIRE 208 2240 400 2240
        END BRANCH
        BEGIN BRANCH A5
            WIRE 208 1680 208 1920
            WIRE 208 1920 416 1920
            WIRE 416 1920 416 2304
            WIRE 416 2304 848 2304
            WIRE 208 1680 512 1680
            WIRE 208 2304 416 2304
        END BRANCH
        BEGIN BRANCH A4
            WIRE 208 2368 432 2368
            WIRE 432 2368 848 2368
            WIRE 224 1744 224 1904
            WIRE 224 1904 432 1904
            WIRE 432 1904 432 2368
            WIRE 224 1744 512 1744
        END BRANCH
        BEGIN BRANCH A3
            WIRE 208 2432 448 2432
            WIRE 448 2432 848 2432
            WIRE 240 1808 256 1808
            WIRE 240 1808 240 1888
            WIRE 240 1888 448 1888
            WIRE 448 1888 448 2432
        END BRANCH
        BEGIN BRANCH A2
            WIRE 208 2496 464 2496
            WIRE 464 2496 848 2496
            WIRE 464 1872 464 2496
            WIRE 464 1872 512 1872
        END BRANCH
        BEGIN BRANCH XLXN_84
            WIRE 816 2624 848 2624
        END BRANCH
        INSTANCE XLXI_42 592 2656 R0
        BEGIN BRANCH XLXN_85
            WIRE 816 2560 848 2560
        END BRANCH
        INSTANCE XLXI_43 592 2592 R0
        BEGIN BRANCH A1
            WIRE 208 2560 480 2560
            WIRE 480 2560 592 2560
            WIRE 480 1936 480 2560
            WIRE 480 1936 512 1936
        END BRANCH
        BEGIN BRANCH A0
            WIRE 208 2624 496 2624
            WIRE 496 2624 592 2624
            WIRE 496 2000 512 2000
            WIRE 496 2000 496 2624
        END BRANCH
        IOMARKER 208 2176 A7 R180 28
        IOMARKER 208 2240 A6 R180 28
        IOMARKER 208 2304 A5 R180 28
        IOMARKER 208 2368 A4 R180 28
        IOMARKER 208 2432 A3 R180 28
        IOMARKER 208 2560 A1 R180 28
        IOMARKER 208 2624 A0 R180 28
        IOMARKER 208 2496 A2 R180 28
        BEGIN BRANCH XLXN_182
            WIRE 2144 1776 2144 1888
            WIRE 2144 1888 2160 1888
            WIRE 2144 1776 2256 1776
            WIRE 2256 1680 2256 1776
        END BRANCH
        BEGIN BRANCH EVENT_L
            WIRE 2544 1888 2768 1888
            WIRE 2768 1888 2784 1888
            WIRE 2784 1888 2784 2032
            WIRE 2784 2032 2800 2032
            WIRE 2784 1888 2832 1888
            WIRE 2832 1888 2944 1888
            WIRE 2768 1312 2768 1888
            WIRE 2768 1312 2864 1312
            BEGIN DISPLAY 2832 1888 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A7
            WIRE 2592 1376 2752 1376
            WIRE 2752 1376 2944 1376
            WIRE 2752 1376 2752 2096
            WIRE 2752 2096 2800 2096
            WIRE 2752 800 2752 1376
            WIRE 2752 800 2864 800
            BEGIN DISPLAY 2592 1376 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A6
            WIRE 2592 1440 2736 1440
            WIRE 2736 1440 2944 1440
            WIRE 2736 1440 2736 2160
            WIRE 2736 2160 3056 2160
            WIRE 2736 864 2736 1440
            WIRE 2736 864 2864 864
            BEGIN DISPLAY 2592 1440 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A5
            WIRE 2592 1504 2720 1504
            WIRE 2720 1504 2944 1504
            WIRE 2720 1504 2720 2224
            WIRE 2720 2224 3056 2224
            WIRE 2720 928 2720 1504
            WIRE 2720 928 3120 928
            BEGIN DISPLAY 2592 1504 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A4
            WIRE 2592 1568 2704 1568
            WIRE 2704 1568 2944 1568
            WIRE 2704 1568 2704 2288
            WIRE 2704 2288 2800 2288
            WIRE 2704 992 2704 1568
            WIRE 2704 992 3120 992
            BEGIN DISPLAY 2592 1568 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A3
            WIRE 2592 1632 2688 1632
            WIRE 2688 1632 2944 1632
            WIRE 2688 1632 2688 2352
            WIRE 2688 2352 2800 2352
            WIRE 2688 1056 2688 1632
            WIRE 2688 1056 3120 1056
            BEGIN DISPLAY 2592 1632 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A2
            WIRE 2592 1696 2672 1696
            WIRE 2672 1696 2944 1696
            WIRE 2672 1696 2672 2416
            WIRE 2672 2416 3056 2416
            WIRE 2672 1120 2672 1696
            WIRE 2672 1120 2864 1120
            BEGIN DISPLAY 2592 1696 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A1
            WIRE 2592 1760 2656 1760
            WIRE 2656 1760 2944 1760
            WIRE 2656 1760 2656 2480
            WIRE 2656 2480 3056 2480
            WIRE 2656 1184 2656 1760
            WIRE 2656 1184 2864 1184
            BEGIN DISPLAY 2592 1760 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH A0
            WIRE 2592 1824 2640 1824
            WIRE 2640 1824 2944 1824
            WIRE 2640 1824 2640 2544
            WIRE 2640 2544 2800 2544
            WIRE 2640 1248 2640 1824
            WIRE 2640 1248 2864 1248
            BEGIN DISPLAY 2592 1824 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_72 656 1376 R0
        INSTANCE XLXI_73 848 2688 R0
        BEGIN BRANCH EXECZERO
            WIRE 864 1376 1008 1376
            WIRE 864 1376 864 1696
            WIRE 864 1696 1440 1696
            WIRE 1440 1696 1440 2592
            WIRE 1440 2592 3472 2592
            WIRE 3200 1632 3200 1632
            WIRE 3200 1632 3472 1632
            WIRE 3472 1632 3472 2592
            BEGIN DISPLAY 864 1376 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
            BEGIN DISPLAY 3208 1632 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_68 2944 1952 R0
        INSTANCE XLXI_74 3056 2608 R0
        BEGIN BRANCH XLXN_207
            WIRE 3024 2032 3056 2032
        END BRANCH
        INSTANCE XLXI_75 2800 2064 R0
        BEGIN BRANCH XLXN_208
            WIRE 3024 2096 3056 2096
        END BRANCH
        INSTANCE XLXI_76 2800 2128 R0
        BEGIN BRANCH XLXN_209
            WIRE 3024 2288 3056 2288
        END BRANCH
        INSTANCE XLXI_77 2800 2320 R0
        BEGIN BRANCH XLXN_210
            WIRE 3024 2352 3056 2352
        END BRANCH
        INSTANCE XLXI_78 2800 2384 R0
        BEGIN BRANCH XLXN_211
            WIRE 3024 2544 3056 2544
        END BRANCH
        INSTANCE XLXI_79 2800 2576 R0
        INSTANCE EVENT 2160 2144 R0
        BEGIN BRANCH EXECNMI
            WIRE 896 1520 896 1728
            WIRE 896 1728 1408 1728
            WIRE 1408 1728 1408 2640
            WIRE 1408 2640 1856 2640
            WIRE 1856 2640 3424 2640
            WIRE 896 1520 1008 1520
            WIRE 3312 2288 3424 2288
            WIRE 3424 2288 3424 2640
            BEGIN DISPLAY 896 1520 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
            BEGIN DISPLAY 1852 2640 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_81 3120 1376 R0
        BEGIN BRANCH XLXN_222
            WIRE 3088 1312 3120 1312
        END BRANCH
        INSTANCE XLXI_82 2864 1344 R0
        BEGIN BRANCH XLXN_223
            WIRE 3088 800 3120 800
        END BRANCH
        INSTANCE XLXI_83 2864 832 R0
        BEGIN BRANCH XLXN_224
            WIRE 3088 864 3120 864
        END BRANCH
        INSTANCE XLXI_84 2864 896 R0
        BEGIN BRANCH XLXN_225
            WIRE 3088 1120 3120 1120
        END BRANCH
        INSTANCE XLXI_85 2864 1152 R0
        BEGIN BRANCH XLXN_226
            WIRE 3088 1184 3120 1184
        END BRANCH
        INSTANCE XLXI_86 2864 1216 R0
        BEGIN BRANCH XLXN_227
            WIRE 3088 1248 3120 1248
        END BRANCH
        INSTANCE XLXI_87 2864 1280 R0
        BEGIN BRANCH EXECINT
            WIRE 928 1664 928 1760
            WIRE 928 1760 1376 1760
            WIRE 1376 1760 1376 2672
            WIRE 1376 2672 3504 2672
            WIRE 928 1664 1008 1664
            WIRE 3376 1056 3456 1056
            WIRE 3456 1056 3504 1056
            WIRE 3504 1056 3504 2672
            BEGIN DISPLAY 928 1664 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
            BEGIN DISPLAY 3464 1056 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_89 1008 1440 R0
        INSTANCE XLXI_90 1008 1728 R0
        INSTANCE XLXI_91 1008 1584 R0
        BEGIN BRANCH XLXN_232
            WIRE 1264 1344 1280 1344
            WIRE 1280 352 1280 1344
            WIRE 1280 352 1376 352
        END BRANCH
        BEGIN BRANCH XLXN_233
            WIRE 1264 1488 1296 1488
            WIRE 1296 416 1296 1488
            WIRE 1296 416 1376 416
        END BRANCH
        BEGIN BRANCH XLXN_234
            WIRE 1264 1632 1312 1632
            WIRE 1312 480 1312 1632
            WIRE 1312 480 1376 480
        END BRANCH
        INSTANCE XLXI_93 512 2064 R0
        BEGIN BRANCH RST8EN_L
            WIRE 272 1488 288 1488
            WIRE 288 1488 512 1488
        END BRANCH
        IOMARKER 272 1488 RST8EN_L R180 28
        BEGIN BRANCH XLXN_238
            WIRE 480 1808 496 1808
            WIRE 496 1808 512 1808
        END BRANCH
        INSTANCE XLXI_95 256 1840 R0
        INSTANCE XLXI_96 1008 1936 R0
        BEGIN BRANCH XLXN_240
            WIRE 768 1744 848 1744
            WIRE 848 1744 848 1872
            WIRE 848 1872 992 1872
            WIRE 992 1872 1008 1872
        END BRANCH
        IOMARKER 1984 112 IORQ R180 28
        BEGIN BRANCH CS_L
            WIRE 3344 608 3408 608
        END BRANCH
        IOMARKER 224 672 M1_L R180 28
        IOMARKER 1504 688 MREQ_L R180 28
        BEGIN BRANCH XLXN_52
            WIRE 1104 2400 1344 2400
            WIRE 1344 1088 1344 2400
            WIRE 1344 1088 1392 1088
        END BRANCH
        INSTANCE XLXI_103 1392 1152 R0
        BEGIN BRANCH XLXN_53
            WIRE 912 1056 976 1056
            WIRE 976 1056 976 1312
            WIRE 976 1312 1008 1312
            WIRE 976 1312 976 1456
            WIRE 976 1456 1008 1456
            WIRE 976 1456 976 1600
            WIRE 976 1600 1008 1600
            WIRE 976 1600 976 1808
            WIRE 976 1808 1008 1808
            WIRE 976 1024 1392 1024
            WIRE 976 1024 976 1056
        END BRANCH
        INSTANCE XLXI_67 2192 1680 R0
        BEGIN BRANCH XLXN_257
            WIRE 1664 848 1680 848
            WIRE 1664 848 1664 912
            WIRE 1664 912 2048 912
            WIRE 2048 912 2048 1376
            WIRE 2032 1376 2048 1376
        END BRANCH
        INSTANCE XLXI_105 1680 912 R0
        IOMARKER 3408 608 CS_L R0 28
        IOMARKER 3344 128 A15OUT R0 28
        INSTANCE XLXI_101 3088 768 R0
        IOMARKER 3296 416 HLDROMCS R0 28
        INSTANCE XLXI_133 2672 544 R0
        BEGIN BRANCH CALLTRAP
            WIRE 2656 480 2672 480
            BEGIN DISPLAY 2656 480 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_102 1648 1632 R0
        BEGIN BRANCH XLXN_252
            WIRE 1584 1232 1584 1376
            WIRE 1584 1376 1648 1376
            WIRE 1584 1232 1664 1232
            WIRE 1648 1056 1664 1056
            WIRE 1664 1056 1664 1232
        END BRANCH
        IOMARKER 1616 1808 CLK R90 28
        BEGIN BRANCH XLXN_344
            WIRE 2128 2112 2160 2112
        END BRANCH
        INSTANCE XLXI_135 1904 2144 R0
        BEGIN BRANCH RESET_L
            WIRE 1872 2112 1904 2112
        END BRANCH
        IOMARKER 1872 2112 RESET_L R180 28
        BEGIN BRANCH XLXN_357
            WIRE 1616 1504 1648 1504
        END BRANCH
        INSTANCE XLXI_141 1392 1536 R0
        BEGIN BRANCH CLK
            WIRE 1360 1504 1392 1504
            WIRE 1360 1504 1360 1632
            WIRE 1360 1632 1616 1632
            WIRE 1616 1632 1616 1808
        END BRANCH
        INSTANCE XLXI_142 1376 608 R0
        BEGIN BRANCH XLXN_241
            WIRE 1264 1840 1328 1840
            WIRE 1328 544 1328 576
            WIRE 1328 576 1328 1840
            WIRE 1328 544 1376 544
        END BRANCH
    END SHEET
    BEGIN SHEET 2 3520 2720
        INSTANCE XLXI_107 576 800 R0
        BEGIN BRANCH XLXN_265
            WIRE 544 352 576 352
        END BRANCH
        INSTANCE XLXI_108 320 384 R0
        BEGIN BRANCH XLXN_266
            WIRE 544 416 576 416
        END BRANCH
        INSTANCE XLXI_109 320 448 R0
        BEGIN BRANCH D0
            WIRE 160 672 192 672
            WIRE 192 672 576 672
            WIRE 192 672 192 2112
            WIRE 192 2112 576 2112
        END BRANCH
        BEGIN BRANCH XLXN_268
            WIRE 544 608 576 608
        END BRANCH
        INSTANCE XLXI_111 320 640 R0
        BEGIN BRANCH XLXN_269
            WIRE 544 736 576 736
        END BRANCH
        INSTANCE XLXI_112 320 768 R0
        BEGIN BRANCH M1_L
            WIRE 160 736 320 736
            BEGIN DISPLAY 160 736 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        IOMARKER 160 224 D7 R180 28
        BEGIN BRANCH D6
            WIRE 160 288 288 288
            WIRE 288 288 576 288
            WIRE 288 288 288 1072
            WIRE 288 1072 560 1072
            WIRE 288 1072 288 1728
            WIRE 288 1728 304 1728
        END BRANCH
        IOMARKER 160 288 D6 R180 28
        BEGIN BRANCH D5
            WIRE 160 352 272 352
            WIRE 272 352 320 352
            WIRE 272 352 272 1136
            WIRE 272 1136 560 1136
            WIRE 272 1136 272 1792
            WIRE 272 1792 576 1792
        END BRANCH
        BEGIN BRANCH D4
            WIRE 160 416 256 416
            WIRE 256 416 320 416
            WIRE 256 416 256 1200
            WIRE 256 1200 560 1200
            WIRE 256 1200 256 1856
            WIRE 256 1856 576 1856
        END BRANCH
        BEGIN BRANCH D3
            WIRE 160 480 240 480
            WIRE 240 480 576 480
            WIRE 240 480 240 1264
            WIRE 240 1264 560 1264
            WIRE 240 1264 240 1920
            WIRE 240 1920 576 1920
        END BRANCH
        BEGIN BRANCH D2
            WIRE 160 544 224 544
            WIRE 224 544 576 544
            WIRE 224 544 224 1984
            WIRE 224 1984 576 1984
        END BRANCH
        BEGIN BRANCH D1
            WIRE 160 608 208 608
            WIRE 208 608 320 608
            WIRE 208 608 208 2048
            WIRE 208 2048 576 2048
        END BRANCH
        IOMARKER 160 352 D5 R180 28
        IOMARKER 160 416 D4 R180 28
        IOMARKER 160 480 D3 R180 28
        IOMARKER 160 544 D2 R180 28
        IOMARKER 160 608 D1 R180 28
        IOMARKER 160 672 D0 R180 28
        BEGIN BRANCH XLXN_279
            WIRE 832 480 944 480
        END BRANCH
        BEGIN BRANCH XLXN_282
            WIRE 1328 480 1584 480
        END BRANCH
        INSTANCE XLXI_116 1584 736 R0
        INSTANCE XLXI_123 384 208 R0
        BEGIN BRANCH MREQ_L
            WIRE 224 80 384 80
            BEGIN DISPLAY 224 80 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH RD_L
            WIRE 160 144 384 144
        END BRANCH
        IOMARKER 160 144 RD_L R180 28
        BEGIN BRANCH XLXN_295
            WIRE 640 112 1424 112
            WIRE 1424 112 1424 608
            WIRE 1424 608 1584 608
            WIRE 1424 608 1424 1296
            WIRE 1424 1296 1424 1984
            WIRE 1424 1984 1600 1984
            WIRE 1424 1296 1584 1296
        END BRANCH
        BEGIN BRANCH XLXN_298
            WIRE 1328 1168 1584 1168
        END BRANCH
        INSTANCE XLXI_130 1600 2112 R0
        BEGIN BRANCH XLXN_310
            WIRE 1328 1920 1600 1920
        END BRANCH
        BEGIN BRANCH XLXN_311
            WIRE 1568 1856 1600 1856
        END BRANCH
        INSTANCE XLXI_132 1504 1856 R0
        BEGIN BRANCH PAGEOUT
            WIRE 1504 2080 1600 2080
            BEGIN DISPLAY 1504 2080 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        BEGIN BRANCH D7
            WIRE 160 224 304 224
            WIRE 304 224 576 224
            WIRE 304 224 304 1008
            WIRE 304 1008 560 1008
            WIRE 304 1008 304 1664
        END BRANCH
        INSTANCE XLXI_126 560 1392 R0
        INSTANCE XLXI_120 576 2240 R0
        BEGIN BRANCH XLXN_285
            WIRE 528 1728 576 1728
        END BRANCH
        INSTANCE XLXI_119 304 1760 R0
        INSTANCE XLXI_118 304 1696 R0
        BEGIN BRANCH XLXN_284
            WIRE 528 1664 576 1664
        END BRANCH
        INSTANCE XLXI_125 1584 1424 R0
        BEGIN BRANCH XLXN_336
            WIRE 816 1168 944 1168
        END BRANCH
        BEGIN BRANCH XLXN_337
            WIRE 160 864 2064 864
            WIRE 160 864 160 1328
            WIRE 160 1328 560 1328
            WIRE 1968 480 2064 480
            WIRE 2064 480 2064 864
        END BRANCH
        BEGIN BRANCH XLXN_338
            WIRE 832 1920 944 1920
        END BRANCH
        BEGIN BRANCH XLXN_339
            WIRE 160 1488 2064 1488
            WIRE 160 1488 160 2176
            WIRE 160 2176 576 2176
            WIRE 1968 1168 2064 1168
            WIRE 2064 1168 2064 1488
        END BRANCH
        BEGIN BRANCH CALLTRAP
            WIRE 1984 1856 2048 1856
            WIRE 2048 1856 2160 1856
            BEGIN DISPLAY 2051 1856 ATTR Name
                ALIGNMENT SOFT-BCENTER
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_137 944 2176 R0
        INSTANCE XLXI_138 944 1424 R0
        INSTANCE XLXI_139 944 736 R0
        BEGIN BRANCH CLK
            WIRE 848 2048 896 2048
            WIRE 896 2048 944 2048
            WIRE 880 832 880 1296
            WIRE 880 1296 896 1296
            WIRE 896 1296 896 2048
            WIRE 896 1296 944 1296
            BEGIN DISPLAY 848 2048 ATTR Name
                ALIGNMENT SOFT-RIGHT
            END DISPLAY
        END BRANCH
        INSTANCE XLXI_140 912 832 R270
        BEGIN BRANCH XLXN_356
            WIRE 880 528 880 608
            WIRE 880 528 928 528
            WIRE 928 528 928 608
            WIRE 928 608 944 608
        END BRANCH
    END SHEET
END SCHEMATIC
