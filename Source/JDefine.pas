(****************************************************************************
 *
 *            WinLIRC plug-in for jetAudio
 *
 *            Copyright (c) 2016 Tim De Baets
 *
 ****************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ****************************************************************************
 *
 * jetAudio API defines
 *
 ****************************************************************************)

unit JDefine;
{**************************************************************************}
{                                                                          }
{    This C DLL header file first (automatic) conversion generated by:     }
{    HeadConv 4.0 (c) 2000 by Bob Swart (aka Dr.Bob - www.drbob42.com)     }
{      Final Delphi-Jedi (Darth) command-line units edition                }
{                                                                          }
{    Generated Date: 15/04/2009                                            }
{    Generated Time: 19:50:07                                              }
{                                                                          }
{**************************************************************************}

interface

uses
{$IFDEF WIN32}
  Windows, Messages;
{$ELSE}
  Wintypes, WinProcs;
{$ENDIF}


{=> jetaudio7_pluginsdk\include\JDEFINE.H <=}

{/// }
{/// All filters should have this function }
{/// }
type
  LPJPLUGINCREATE = function(pszStoreRoot: PAnsiChar): Pointer;

{/// }
{/// Plugin Status }
{/// }
type
  JMODE = (
    JMODE_NOT_OPEN, 
    JMODE_STOP, 
    JMODE_PLAY, 
    JMODE_PAUSE, 
    JMODE_SEEK, 
    JMODE_CONNECTING, 
    JMODE_BUFFERING );

type
  JERROR_TYPE = (
    JERROR_UNKNOWN, 
    JERROR_CRITICAL, 
    JERROR_WARNING, 
    JERROR_INFORMATION, 
    JERROR_NO_ENGINE  );

{/// Reader Plugin status }
type
  JOPEN_STATUS = (
    JOPEN_ERROR, 
    JOPEN_OK, 
    JOPEN_CONNECTING, 
    JOPEN_BUFFERING  );

{/// Writer Plugin status }
type
  JOUTPUT_STATUS = (
    JOUTPUT_FINISHED, 
    JOUTPUT_RUNNING, 
    JOUTPUT_BUFFERING  );

{/////////////////////////////////////////////////////////////////////////// }
{/// Notify message from Plugin }
const
  WM_JPLUGIN_NOTIFY = (WM_APP+8732);
{/// WPARAM is [NOTIFY_CODE] }
{/// Notify Codes }
const
  JNOTIFY_OPENED = (1);
const
  JNOTIFY_MODE_CHANGED = (4);
const
  JNOTIFY_TIME_CHANGED = (5);
const
  JNOTIFY_UOPF_CHANGED = (6);
const
  JNOTIFY_VIDEOWND_NEEDED = (7);
const
  JNOTIFY_ADD_NEXT = (8);
const
  JNOTIFY_PROP_CHANGED = (10);
const
  JNOTIFY_BUFFERING = (13); {// lParam is % value of buffering status}
const
  JNOTIFY_INDEXING = (14); {// lParam is % value of indexing status}
const
  JNOTIFY_SEARCHING = (15); {// lParam is % value of indexing status}

const
  JNOTIFY_DOMAIN_CHANGED = (20);
const
  JNOTIFY_TITLE_CHANGED = (21);
const
  JNOTIFY_CHAPTER_CHANGED = (22); {// lParam is Chapter Number}
const
  JNOTIFY_AUDIO_CHANGED = (23);
const
  JNOTIFY_SUBTITLE_CHANGED = (24);
const
  JNOTIFY_ANGLE_CHANGED = (25);
const
  JNOTIFY_KARAOKE_CHANGED = (26);
const
  JNOTIFY_PLAYBACK_RATE_CHANGED = (27);
const
  JNOTIFY_PARENTAL_LEVEL_CHANGED = (28);
const
  JNOTIFY_CAPTION_CHANGED = (29);

const
  JNOTIFY_COLOR_CHANGED = (50);

const
  JNOTIFY_OSD_TIME = (100);
const
  JNOTIFY_OSD_VOLUME = (101);
const
  JNOTIFY_OSD_MUTE = (102);
const
  JNOTIFY_OSD_SPEED = (103);
const
  JNOTIFY_OSD_BUFFERING = (104);
const
  JNOTIFY_OSD_INDEXING = (105);
const
  JNOTIFY_OSD_SEARCHING = (106);
const
  JNOTIFY_OSD_COLOR_BRIGHTNESS = (110);
const
  JNOTIFY_OSD_COLOR_CONTRAST = (111);
const
  JNOTIFY_OSD_COLOR_HUE = (112);
const
  JNOTIFY_OSD_COLOR_SATURATION = (113);
const
  JNOTIFY_OSD_COLOR_GAMMA = (114);
const
  JNOTIFY_OSD_COLOR_RESET = (115);
const
  JNOTIFY_OSD_AUDIO = (120);
const
  JNOTIFY_OSD_ANGLE = (121);
const
  JNOTIFY_OSD_SUBTITLE_LANG = (130);
const
  JNOTIFY_OSD_SUBTITLE_TIMING = (131);
const
  JNOTIFY_OSD_SUBTITLE_SIZE = (132);

const
  JNOTIFY_ERROR = (-1);
const
  JNOTIFY_ERROR_ENGINE = (-2); {// lParam is EngineType (1:RM, 2:WM)}

{/////////////////////////////////////////////////////////////////////////// }
{/// Category }
{/// }
{/// High Level Plugins }
const
  JCATEGORY_PLAYER_AUDIOCD = (1);
const
  JCATEGORY_PLAYER_VIDEOCD = (2);
const
  JCATEGORY_PLAYER_DVD = (3);
const
  JCATEGORY_PLAYER_FILE = (4);
const
  JCATEGORY_PLAYER_TV = (5);
const
  JCATEGORY_PLAYER_RADIO = (6);

{/// General Plugins (Always loaded with jetAudio) }
const
  JCATEGORY_GENERAL = (50);

{/// Stream Plugins }
const
  JCATEGORY_STREAM_AUDIO_READER = (100);

const
  JCATEGORY_STREAM_AUDIO_WRITER = (110);

const
  JCATEGORY_STREAM_AUDIO_CODEC = (120);

const
  JCATEGORY_STREAM_AUDIO_EFFECTOR = (130);

const
  JCATEGORY_STREAM_AUDIOCD_READER = (140);

const
  JCATEGORY_STREAM_AUDIOCD_WRITER = (150);

{/////////////////////////////////////////////////////////////////////////// }
{/// IO Device Type }
const
  JDEVICE_DEVICE = ($00000001);
const
  JDEVICE_FILE = ($00000002);
const
  JDEVICE_STREAM = ($00000004);
const
  JDEVICE_DISC_ACD = ($00000010);
const
  JDEVICE_DISC_VCD = ($00000020);
const
  JDEVICE_DISC_DVD = ($00000040);

const
  JDEVICE_UNKNOWN = ($00008000);

const
  JDEVICE_ANY = ($0000FFF);

{/////////////////////////////////////////////////////////////////////////// }
{/// IO Stream Type }
const
  JSTREAM_PCM = ($00000001);
const
  JSTREAM_MP3 = ($00000002);
const
  JSTREAM_WMA = ($00000004);
const
  JSTREAM_ACM = ($00000008);
const
  JSTREAM_OGG = ($00000010);
const
  JSTREAM_RM = ($00000020);
const
  JSTREAM_APE = ($00000040);
const
  JSTREAM_MPC = ($00000080);
const
  JSTREAM_VQF = ($00000100);
const
  JSTREAM_FLAC = ($00000200);
const
  JSTREAM_SPX = ($00000400);

const
  JSTREAM_UNKNOWN = ($00008000);

const
  JSTREAM_ANY = ($0000FFF);

{/// Filter Caps (used in JFInfo) }
const
  JCAPS_HAS_CONFIG = ($00000001);
const
  JCAPS_HAS_ABOUTBOX = ($00000002);

{/////////////////////////////////////////////////////////////////////////// }
{/// }
{/// General Properties for Tags }
const
  JPROP_TITLE = PAnsiChar(1);
const
  JPROP_ARTIST = PAnsiChar(2);
const
  JPROP_ALBUM = PAnsiChar(3);
const
  JPROP_YEAR = PAnsiChar(4);
const
  JPROP_COPYRIGHT = PAnsiChar(5);
const
  JPROP_COMMENT = PAnsiChar(6);
const
  JPROP_GENRE = PAnsiChar(7);
const
  JPROP_URL = PAnsiChar(8);
const
  JPROP_TRACK = PAnsiChar(9);
const
  JPROP_IMAGE = PAnsiChar(10);
const
  JPROP_LYRIC = PAnsiChar(11);
const
  JPROP_COMPILATION = PAnsiChar(12);
const
  JPROP_TAG = PAnsiChar(19);

const
  JPROP_CUR_AUDIO = PAnsiChar(20);
const
  JPROP_CUR_SUBTITLE = PAnsiChar(21);
const
  JPROP_CUR_ANGLE = PAnsiChar(22);
const
  JPROP_KARAOKE = PAnsiChar(23);
const
  JPROP_SUBTITLE_FLAG = PAnsiChar(24);
const
  JPROP_SUBTITLE_FONTNAME = PAnsiChar(25);
const
  JPROP_SUBTITLE_FONTSIZE = PAnsiChar(26);
const
  JPROP_NUM_AUDIO = PAnsiChar(27);
const
  JPROP_NUM_SUBTITLE = PAnsiChar(28);
const
  JPROP_NUM_ANGLE = PAnsiChar(29);

const
  JPROP_CAPTION = PAnsiChar(30); {// closed-caption}

{/// File Properties }
const
  JPROP_BITRATE = PAnsiChar(40); {// birate (bps)}
const
  JPROP_SAMPLERATE = PAnsiChar(41); {// frequency}
const
  JPROP_CHANNEL = PAnsiChar(42); {// 1:Mono, 2:Stereo, or multichannel ?}
const
  JPROP_ATTR_STRING = PAnsiChar(49); {// attrbiute as string}

{/// JCAPS_SPEED }
const
  JPROP_SPEED = PAnsiChar(100);

{/// JCAPS_KEY }
const
  JPROP_KEY = PAnsiChar(101);

{/// JCAPS_PITCH }
const
  JPROP_PITCH = PAnsiChar(102);

{/// JCAPS_EQ }
const
  JPROP_EQGAIN = PAnsiChar(110);

{/// JCAPS_SPECTRUM }
const
  JPROP_SPECTRUM = PAnsiChar(111);

{/// JCAPS_CROSSFADE }
const
  JPROP_CROSSFADE = PAnsiChar(130); {// crossfade on-off}

{/// JCAPS_FADE }
const
  JPROP_FADEIN = PAnsiChar(150);
const
  JPROP_FADEOUT = PAnsiChar(151);

{/// Used for CD Player }
const
  JPROP_DIGITAL_CD_PLAYBACK = PAnsiChar(190);

{/// General Flags for Effectors }
const
  JPROP_FLAG = PAnsiChar(200);
const
  JPROP_DEPTH = PAnsiChar(201);
const
  JPROP_MODE = PAnsiChar(202);
const
  JPROP_MODE_NUM = PAnsiChar(203);
const
  JPROP_MODE_NAME = PAnsiChar(204);

{/// for SDK 2 }
const
  JPROP_PLUGIN_INFO2 = PAnsiChar(500);

{/////////////////////////////////////////////////////////////////////////// }

const
  MAX_AUDIO_CHANNELS = (8);
const
  MAX_EQ_BAND = (20);
const
  MAX_SPECTRUM_BAND = (20);


{/////////////////////////////////////////////////////////////////////////// }
{/// UOP Flag (used in GetUOPFlag() function) }
{/// These flags are used for Button/Menu Status (Enable / Disable) }
{/// Following constants are fully compatible with DVD Specification }
const
  JUOP_FLAG_Play_Title_Or_AtTime = ($00000001);
const
  JUOP_FLAG_Play_Chapter = ($00000002);
const
  JUOP_FLAG_Play_Title = ($00000004);
const
  JUOP_FLAG_Stop = ($00000008);
const
  JUOP_FLAG_ReturnFromSubMenu = ($00000010);
const
  JUOP_FLAG_Play_Chapter_Or_AtTime = ($00000020);
const
  JUOP_FLAG_PlayPrev_Or_Replay_Chapter = ($00000040);
const
  JUOP_FLAG_PlayNext_Chapter = ($00000080);
const
  JUOP_FLAG_Play_Forwards = ($00000100);
const
  JUOP_FLAG_Play_Backwards = ($00000200);
const
  JUOP_FLAG_ShowMenu_Title = ($00000400);
const
  JUOP_FLAG_ShowMenu_Root = ($00000800);
const
  JUOP_FLAG_ShowMenu_Subtitle = ($00001000);
const
  JUOP_FLAG_ShowMenu_Audio = ($00002000);
const
  JUOP_FLAG_ShowMenu_Angle = ($00004000);
const
  JUOP_FLAG_ShowMenu_Chapter = ($00008000);
const
  JUOP_FLAG_Resume = ($00010000);
const
  JUOP_FLAG_Select_Or_Activate_Button = ($00020000);
const
  JUOP_FLAG_Still_Off = ($00040000);
const
  JUOP_FLAG_Pause_On = ($00080000);
const
  JUOP_FLAG_Select_Audio_Stream = ($00100000);
const
  JUOP_FLAG_Select_Subtitle_Stream = ($00200000);
const
  JUOP_FLAG_Select_Angle = ($00400000);
const
  JUOP_FLAG_Select_Karaoke_Audio_Presentation_Mode = ($00800000);
const
  JUOP_FLAG_Select_Video_Mode_Preference = ($01000000);
{/// Added by us }
const
  JUOP_FLAG_Capture_Image = ($80000000);
const
  JUOP_FLAG_Play_Default = ($40000000);
const
  JUOP_FLAG_Change_Pitch = ($20000000);
const
  JUOP_FLAG_Change_Playback_Rate = ($10000000);
const
  JUOP_FLAG_Frame_Step = ($08000000);

const
  JUOP_FLAG_All_Enabled = ($00000000);
const
  JUOP_FLAG_All_Disabled = ($FFFFFFF);

type
  JStreamBuffer = record
    Buffer: PBYTE;
    BufferSize: Integer;
    DataSize: Integer;
    DataUsed: Integer;
  end {JStreamBuffer};

implementation

end.
