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
/*  SQLStreamSupplier.cls  -  SQLStreamSupplier class                       */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library . . . . Rexx/SQL interface by Mark Hessling           */
/*                              http://www.lightlink.com/hessling/          */
/*    SQLObject.cls . . . . . SQLObject class                               */
/*    SQLStream.cls . . . . . SQLStream class (required by)                 */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLObject.cls'

/*--------------------------------------------------------------------------*/
/* SQLStreamSupplier Class definition                                       */
/*--------------------------------------------------------------------------*/
::CLASS SQLStreamSupplier SUBCLASS SQLObject PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLStreamSupplier instance variables                                     */
/*--------------------------------------------------------------------------*/
::METHOD rows ATTRIBUTE PRIVATE    /* row set array  */
::METHOD i ATTRIBUTE PRIVATE       /* row set index  */
::METHOD n ATTRIBUTE PRIVATE       /* number of rows */

/*--------------------------------------------------------------------------*/
/* SQLStreamSupplier Instance Methods                                       */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init                                                            */
/*   - initializes the supplier object with the contents of the input       */
/*     stream of the SQLStream object it is being created for.              */
/*   - Argument 1                                                           */
/*      A SQLStream object with a defined input stream.                     */
/*--------------------------------------------------------------------------*/
::METHOD Init
	expose sqlca.
    use arg sqlStream, selectStmt
	signal on USER SQLError NAME InitError

	if (\Var('selectStmt')) then do
		self~rows = sqlStream~MakeArray
		/*self~rows = sqlStream~ArrayIn(0)*/
	end
	else do
		self~rows = sqlStream~ArrayIn(0, selectStmt)
	end
	self~i = 1
	self~n = self~rows~items
	
	return

	InitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Available                                                       */
/*   - Returns 1 if an item is available from the supplier. Returns 0       */
/*     otherwise.                                                           */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Available

	if (self~i <= self~n) then return 1
	else return 0

/*--------------------------------------------------------------------------*/
/* ::METHOD Index                                                           */
/*   - Returns the index of the current item.                               */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Index

	return self~i

/*--------------------------------------------------------------------------*/
/* ::METHOD Item                                                            */
/*   - Returns the current item. For SQLSteamSupplier objects, this is a    */
/*     Stem object, indexed by column name.                                 */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Item

	return self~rows[self~i]

/*--------------------------------------------------------------------------*/
/* ::METHOD Next                                                            */
/*   - Moves to the next item in the supplier object.                       */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Next

	self~i = self~i + 1
