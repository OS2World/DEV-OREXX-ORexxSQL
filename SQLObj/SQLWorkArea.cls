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
/*  SQLWorkArea.cls  -  SQLWorkArea class                                   */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library  . . . . . Rexx/SQL interface by Mark Hessling        */
/*                                 http://www.lightlink.com/hessling/       */
/*    SQLObject.cls  . . . . . . SQLObject class                            */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLObject.cls'

/*--------------------------------------------------------------------------*/
/* SQLWorkArea Class definition                                             */
/*--------------------------------------------------------------------------*/
::CLASS SQLWorkArea SUBCLASS SQLObject PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLWorkArea instance variables                                           */
/*--------------------------------------------------------------------------*/
::METHOD connection ATTRIBUTE PRIVATE
::METHOD statementName ATTRIBUTE PRIVATE
::METHOD sqlStatement ATTRIBUTE PRIVATE

/*--------------------------------------------------------------------------*/
/* SQLWorkArea Instance Methods                                             */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init                                                            */
/*   - Initializes the SQLWorkArea object. If no connection object is       */
/*     supplied as an argument, an exception will be raised                 */
/*   - Argument 1                                                           */
/*      A SQLConnection object.                                             */
/*--------------------------------------------------------------------------*/
::METHOD Init
	expose sqlca.
    use arg theConnection
	signal on USER SQLError NAME InitError

	if (\Var('theConnection')) then do
		sqlca.class = self~class
		sqlca.exception = 'Init failed - no connection object supplied'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    self~connection = theConnection
    self~statementName = 's' || self~class~instances
    self~sqlStatement = ''

	return

	InitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD UnInit                                                          */
/*   - This method is automatically invoked when a SQLWorkArea object       */
/*     is destroyed.                                                        */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD UnInit

    self~Dispose

/*--------------------------------------------------------------------------*/
/* ::METHOD Prepare                                                         */
/*   - Prepares a SQL statement for processing.                             */
/*   - Argument 1                                                           */
/*      A valid SQL statement.                                              */
/*--------------------------------------------------------------------------*/
::METHOD Prepare
	expose sqlca.
    use arg newStatement
	signal on USER SQLError NAME PrepareError

    self~Dispose
    self~sqlStatement = newStatement

    self~connection~MakeDefault

	if (SQLPrepare(self~statementName, self~sqlStatement) <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'Prepare failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	PrepareError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Execute                                                         */
/*   - Executes a previously Prepared non-Select SQL statement.             */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Execute 
	expose sqlca.
	signal on USER SQLError NAME  ExecuteError

    self~connection~MakeDefault
	
	if (SQLExecute(self~statementName) <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'Execute failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	ExecuteError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD ExecuteWithBind                                                 */
/*   - Executes a previously Prepared non-Select SQL statement using bind   */
/*     values.                                                              */
/*   - Argument 1                                                           */
/*      A Stem object containing the bind data types.                       */
/*   - Argument 2                                                           */
/*      A Stem object containing the bind values.                           */
/*--------------------------------------------------------------------------*/
::METHOD ExecuteWithBind 
	expose sqlca.
    use arg bindDataTypes., bindValues.
	signal on USER SQLError NAME  ExecuteWithBindError

    self~connection~MakeDefault

	if (SQLExecute(self~statementName, "bindDataTypes.", "bindValues.") <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'ExecuteWithBind failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	ExecuteWithBindError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Dispose                                                         */
/*   - Drops a previously Prepared SQL statement.                           */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Dispose
	expose sqlca.
	signal on USER SQLError NAME  DisposeError

    if (self~sqlStatement <> '') then do
        self~connection~MakeDefault
		if (SQLDispose(self~statementName) <> 0) then do
			sqlca.class = self~class
			sqlca.exception = 'Dispose failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
        self~sqlStatement = ''
    end

	return

	DisposeError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Statement                                                       */
/*   - Returns the currently active SQL statement.                          */
/*   - No arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Statement

	return self~sqlStatement
