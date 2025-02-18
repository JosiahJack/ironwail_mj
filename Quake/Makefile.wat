# makefile to build ironwail.exe for Windows using Open Watcom:
# wmake -f Makefile.wat

### Enable/disable SDL2
USE_SDL2=1

### Enable/disable codecs for streaming music support
USE_CODEC_WAVE=1
USE_CODEC_FLAC=0
USE_CODEC_MP3=1
USE_CODEC_VORBIS=1
USE_CODEC_OPUS=0
# either xmp or mikmod (or modplug)
USE_CODEC_MIKMOD=0
USE_CODEC_XMP=0
USE_CODEC_MODPLUG=0
USE_CODEC_UMX=0

# which library to use for mp3 decoding: mad or mpg123
MP3LIB=mad
# which library to use for ogg decoding: vorbis or tremor
VORBISLIB=vorbis

WINSOCK2= 0

# ---------------------------
# build variables
# ---------------------------

CFLAGS_BASE = -zq -wx -bm -bt=nt -5s -sg -otexan -fp5 -fpi87 -ei -j -zp8
# newer OpenWatcom versions enable W303 by default
CFLAGS_BASE+= -wcd=303
CFLAGS = $(CFLAGS_BASE)

!ifneq USE_SDL2 1
SDL_CFLAGS = -I../Windows/SDL/include
SDL_LIBS = ../Windows/SDL/watcom/SDL.lib
!else
SDL_CFLAGS = -I../Windows/SDL2/include
SDL_LIBS = ../Windows/SDL2/watcom/SDL2.lib
CFLAGS += -DUSE_SDL2
!endif

!ifeq WINSOCK2 1
DEFWINSOCK =-D_USE_WINSOCK2
LIBWINSOCK = ws2_32.lib
!else
DEFWINSOCK =
LIBWINSOCK = wsock32.lib
!endif

CFLAGS    += $(DEFWINSOCK)
NET_LIBS   = $(LIBWINSOCK)

# note:  all codec libraries are static.
CODEC_INC = -I../Windows/codecs/include
LIBCODEC  = ../Windows/codecs/x86-watcom/
!ifeq MP3LIB mad
mp3_obj=snd_mp3
lib_mp3dec=$(LIBCODEC)mad.lib
!endif
!ifeq MP3LIB mpg123
mp3_obj=snd_mpg123
lib_mp3dec=$(LIBCODEC)mpg123.lib
!endif
!ifeq VORBISLIB vorbis
cpp_vorbisdec=
lib_vorbisdec=$(LIBCODEC)vorbisfile.lib $(LIBCODEC)vorbis.lib $(LIBCODEC)ogg.lib
!endif
!ifeq VORBISLIB tremor
cpp_vorbisdec=-DVORBIS_USE_TREMOR
lib_vorbisdec=$(LIBCODEC)vorbisidec.lib $(LIBCODEC)ogg.lib
!endif

CODECLIBS =
!ifeq USE_CODEC_WAVE 1
CFLAGS+= -DUSE_CODEC_WAVE
!endif
!ifeq USE_CODEC_FLAC 1
CFLAGS+= -DUSE_CODEC_FLAC
CFLAGS+= -DFLAC__NO_DLL
CODECLIBS+= $(LIBCODEC)FLAC.lib
!endif
!ifeq USE_CODEC_OPUS 1
CFLAGS+= -DUSE_CODEC_OPUS
CODECLIBS+= $(LIBCODEC)opusfile.lib $(LIBCODEC)opus.lib $(LIBCODEC)ogg.lib
!endif
!ifeq USE_CODEC_VORBIS 1
CFLAGS+= -DUSE_CODEC_VORBIS $(cpp_vorbisdec)
CODECLIBS+= $(lib_vorbisdec)
!endif
!ifeq USE_CODEC_MP3 1
CFLAGS+= -DUSE_CODEC_MP3
CODECLIBS+= $(lib_mp3dec)
!endif
!ifeq USE_CODEC_MIKMOD 1
CFLAGS+= -DUSE_CODEC_MIKMOD
CFLAGS+= -DMIKMOD_STATIC
CODECLIBS+= $(LIBCODEC)mikmod.lib
!endif
!ifeq USE_CODEC_XMP 1
CFLAGS+= -DUSE_CODEC_XMP
CFLAGS+= -DXMP_NO_DLL
CODECLIBS+= $(LIBCODEC)libxmp.lib
!endif
!ifeq USE_CODEC_MODPLUG 1
CFLAGS+= -DUSE_CODEC_MODPLUG
CFLAGS+= -DMODPLUG_STATIC
CODECLIBS+= $(LIBCODEC)modplug.lib
!endif
!ifeq USE_CODEC_UMX 1
CFLAGS+= -DUSE_CODEC_UMX
!endif
CFLAGS+= $(CODEC_INC)

COMMON_LIBS= opengl32.lib winmm.lib

LIBS = $(CODECLIBS) $(SDL_LIBS) $(COMMON_LIBS) $(NET_LIBS)

# ---------------------------
# targets
# ---------------------------

all: ironwail.exe

# ---------------------------
# rules
# ---------------------------

.EXTENSIONS: .res .rc

.c.obj:
	wcc386 $(INCLUDES) $(CFLAGS) $(SDL_CFLAGS) -fo=$^@ $<
SDL_win32_main.obj: ../Windows/SDL/main/SDL_win32_main.c
	wcc386 $(CFLAGS_BASE) $(SDL_CFLAGS) -fo=$^@ $<
SDL_windows_main.obj: ../Windows/SDL2/main/SDL_windows_main.c
	wcc386 $(CFLAGS_BASE) $(SDL_CFLAGS) -I../Windows/SDL2/main -fo=$^@ $<
quakespasm.res: ../Windows/QuakeSpasm.rc
	wrc -q -r -bt=nt -I../Windows -fo=$^@ $<

# ----------------------------------------------------------------------------
# objects
# ----------------------------------------------------------------------------

MUSIC_OBJS= bgmusic.obj &
	snd_codec.obj &
	snd_flac.obj &
	snd_wave.obj &
	snd_vorbis.obj &
	snd_opus.obj &
	$(mp3_obj).obj &
	snd_mp3tag.obj &
	snd_mikmod.obj &
	snd_modplug.obj &
	snd_xmp.obj &
	snd_umx.obj
COMOBJ_SND = snd_dma.obj snd_mix.obj snd_mem.obj $(MUSIC_OBJS)
SYSOBJ_SND = snd_sdl.obj
SYSOBJ_CDA = cd_sdl.obj
SYSOBJ_INPUT = in_sdl.obj
SYSOBJ_GL_VID= gl_vidsdl.obj
SYSOBJ_NET = net_win.obj net_wins.obj net_wipx.obj
SYSOBJ_SYS = pl_win.obj sys_sdl_win.obj
SYSOBJ_MAIN= main_sdl.obj
!ifeq USE_SDL2 1
SYSOBJ_MAIN+= SDL_windows_main.obj
!else
SYSOBJ_MAIN+= SDL_win32_main.obj
!endif
SYSOBJ_RES = quakespasm.res

GLOBJS = &
	gl_refrag.obj &
	gl_rlight.obj &
	gl_rmain.obj &
	gl_fog.obj &
	gl_rmisc.obj &
	r_part.obj &
	r_world.obj &
	gl_screen.obj &
	gl_shaders.obj &
	gl_sky.obj &
	gl_warp.obj &
	$(SYSOBJ_GL_VID) &
	gl_draw.obj &
	image.obj &
	gl_texmgr.obj &
	gl_mesh.obj &
	r_sprite.obj &
	r_alias.obj &
	r_brush.obj &
	gl_model.obj

OBJS = strlcat.obj &
	strlcpy.obj &
	$(GLOBJS) &
	$(SYSOBJ_INPUT) &
	$(COMOBJ_SND) &
	$(SYSOBJ_SND) &
	$(SYSOBJ_CDA) &
	$(SYSOBJ_NET) &
	net_dgrm.obj &
	net_loop.obj &
	net_main.obj &
	chase.obj &
	cl_demo.obj &
	cl_input.obj &
	cl_main.obj &
	cl_parse.obj &
	cl_tent.obj &
	console.obj &
	keys.obj &
	menu.obj &
	sbar.obj &
	view.obj &
	wad.obj &
	cmd.obj &
	common.obj &
	steam.obj &
	miniz.obj &
	crc.obj &
	cvar.obj &
	cfgfile.obj &
	host.obj &
	host_cmd.obj &
	mathlib.obj &
	pr_cmds.obj &
	pr_edict.obj &
	pr_exec.obj &
	sv_main.obj &
	sv_move.obj &
	sv_phys.obj &
	sv_user.obj &
	world.obj &
	zone.obj &
	$(SYSOBJ_SYS) $(SYSOBJ_MAIN)

# ------------------------
# Watcom build rules
# ------------------------

# 1 MB stack size.
ironwail.exe: $(OBJS) quakespasm.res
	wlink N $@ SYS NT_WIN OPTION q OPTION STACK=0x100000 OPTION RESOURCE=$^*.res LIBR {$(LIBS)} F {$(OBJS)}

clean: .symbolic
	rm -f *.obj *.res *.err ironwail.exe
