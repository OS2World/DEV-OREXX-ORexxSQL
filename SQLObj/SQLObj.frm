/*--------------------------------------------------------------------------*/
/*                                                                          */
/*  ORexx/SQL Object Framework v1.0                                         */
/*                                                                          */
/*  Copyright (C) 1997 - 1998, John Blumel.                                 */
/*                                                                          */
/*  This library is free software; you can redistribute it and/or           */
/*  modify it under the terms of the GNU Library General Public             */
/*  License as published by the Free Software Foundation; either            */
/*  version 2 of the License, or (at your option) any later version.        */
/*                                                                          */
/*  This library is distributed in the hope that it will be useful,         */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       */
/*  Library General Public License for more details.                        */
/*                                                                          */
/*  You should have received a copy of the GNU Library General Public       */
/*  License along with this library; if not, write to:                      */
/*                                                                          */
/*            Free Foundation, Inc.                                         */
/*            59 Temple Place                                               */
/*            Suite 330                                                     */
/*            Boston, MA  02111-1307  USA                                   */
/*                                                                          */
/*  Contact: jblumel@acm.org                                                */
/*                                                                          */
/*  Thanks to:                                                              */
/*    Mark Hessling for creating the Rexx/SQL interface, without which,     */
/*      this project would literally not have been possible.                */
/*    Rony Flatscher for sharing his ORexx expertise with me and for        */
/*      his advice on the framework architecture.                           */
/*                                                                          */
/*  SQLObj.frm  -  ORexx/SQL Object Framework ::REQUIRES file               */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library  . . . .  Rexx/SQL interface by Mark Hessling         */
/*                                http://www.lightlink.com/hessling/        */
/*    SQLConnection.cls . . . . SQLConnection class                         */
/*    SQLTable.cls  . . . . . . SQLTable class                              */
/*    SQLResultTable.cls  . . . SQLResultTable class                        */
/*    SQLError.rtn  . . . . . . SQLError class                              */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLConnection.cls'
::REQUIRES 'SQLTable.cls'
::REQUIRES 'SQLResultTable.cls'
::REQUIRES 'SQLError.rtn'
