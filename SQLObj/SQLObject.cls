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
/*  SQLObject.cls  -  SQLObject class                                       */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library  . . . . . Rexx/SQL interface by Mark Hessling        */
/*                                 http://www.lightlink.com/hessling/       */
/*    SQLError.rtn . . . . . . . SQLError Routine                           */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLError.rtn'

/*--------------------------------------------------------------------------*/
/* SQLObject Class definition                                               */
/*--------------------------------------------------------------------------*/
::CLASS SQLObject PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLObject Class Variables                                                */
/*--------------------------------------------------------------------------*/
::METHOD RexxSQLVersion CLASS ATTRIBUTE

/*--------------------------------------------------------------------------*/
/* SQLObject Class Methods                                                  */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init CLASS                                                      */
/*   - Loads the Rexx/SQL library.                                          */
/*   - No Arguments                                                         */
/*--------------------------------------------------------------------------*/
::METHOD Init CLASS
    expose sqlca. instanceCount 

    instanceCount = 0

    if RxFuncQuery('SQLLoadFuncs') then do
        call RxFuncAdd 'SQLLoadFuncs', 'REXXSQL', 'SQLLoadFuncs'
        SIGNAL ON ANY NAME SQLLoadError
        call SQLLoadFuncs
    end
    SQLLoadError: nop
    SIGNAL OFF ANY
	
    self~RexxSQLVersion = SQLVariable("VERSION")

    forward class (super)
 
/*--------------------------------------------------------------------------*/
/* ::METHOD New CLASS                                                       */
/*   - Increments the instance count.                                       */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD New CLASS
    expose instanceCount 
	
    instanceCount = instanceCount + 1

	forward class (super)
 
/*--------------------------------------------------------------------------*/
/* ::METHOD Instances CLASS                                                 */
/*   - Returns the instance count.                                          */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Instances CLASS
    expose instanceCount 

    return instanceCount 

/*--------------------------------------------------------------------------*/
/* ::METHOD UnInit CLASS                                                    */
/*   - Unloads the Rexx/SQL library.                                        */
/*--------------------------------------------------------------------------*/
::METHOD UnInit CLASS

    SIGNAL ON ANY NAME SQLDropError
    call SQLDropFuncs
    SQLDropError: nop
    SIGNAL OFF ANY

/*--------------------------------------------------------------------------*/
/* SQLObject Instance Methods                                               */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Version                                                         */
/*   - Returns the current value of the Rexx/SQL VERSION variable.          */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Version

    return self~class~RexxSQLVersion
