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
/*  SQLTable.cls  -  SQLTable class                                         */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library  . . . . . Rexx/SQL interface by Mark Hessling        */
/*                                http://www.lightlink.com/hessling/        */
/*    SQLWorkArea.cls  . . . . . SQLWorkArea class                          */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLWorkArea.cls'

/*--------------------------------------------------------------------------*/
/* SQLTable Class definition                                                */
/*--------------------------------------------------------------------------*/
::CLASS SQLTable SUBCLASS SQLWorkArea PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLTable Class Methods                                                   */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init CLASS                                                      */
/*   - Removes the ExecuteWithBind method inherited from SQLWorkArea.       */
/*--------------------------------------------------------------------------*/
::METHOD Init CLASS

    self~define('EXECUTEWITHBIND')

	forward class (super)

/*--------------------------------------------------------------------------*/
/* SQLTable instance variables                                              */
/*--------------------------------------------------------------------------*/
::METHOD dbTableName ATTRIBUTE PRIVATE

/*--------------------------------------------------------------------------*/
/* SQLTable Instance Methods                                                */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init                                                            */
/*   - This method is automatically invoked when the SQLTable class is      */
/*     sent a NEW message. Both arguments are required. If either is        */
/*     omitted, an exception will be raised.                                */
/*   - Argument 1                                                           */
/*      A SQLConnection object.                                             */
/*   - Argument 2                                                           */
/*      The name of the database table.                                     */
/*--------------------------------------------------------------------------*/
::METHOD Init
    use arg theConnection, theTable
	signal on USER SQLError NAME InitError

    self~Init:super(theConnection)

	if (\Var('theTable')) then do
		sqlca.class = self~class
		sqlca.exception = 'Init failed - no table name supplied'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    self~dbTableName = theTable

	return

	InitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Insert                                                          */
/*   - Use this method to insert a row into the table.                      */
/*   - Argument 1                                                           */
/*      A Stem, indexed by column name, containing the values to be         */
/*      inserted.                                                           */
/*--------------------------------------------------------------------------*/
::METHOD Insert
	expose sqlca.
    use arg columnValues.
	signal on USER SQLError NAME InsertError


    columnList = '(' 
    valueList = ' VALUES('
	comma = ''
	do colName over columnValues.
        columnList = columnList || comma || colName 
        valueList = valueList || comma || columnValues.colName
		comma = ', '
	end
    columnList = columnList || ')'
    valueList = valueList || ')'

    sqlStatement = 'INSERT INTO ' || self~dbTableName  || columnList || valueList
    self~Prepare(sqlStatement)
    self~Execute

	return

	InsertError: raise propagate
		
/*--------------------------------------------------------------------------*/
/* ::METHOD Update                                                          */
/*   - Use this method to update an existing table row or rows.             */
/*   - Argument 1                                                           */
/*      A Stem, indexed by column name, containing the new column values    */
/*   - Argument 2                                                           */
/*      A string specifying the value for the UPDATE's WHERE clause.        */
/*                                                                          */
/*   	Note: A condition of 'ALL' must be used to update                   */
/*   	      all rows of a table.                                          */
/*--------------------------------------------------------------------------*/
::METHOD Update
	expose sqlca.
    use arg columnValues., condition
	signal on USER SQLError NAME UpdateError

    columnValueList = ''
	comma = ''
	do colName over columnValues.
        columnValueList = columnValueList || comma || colName || '=' || columnValues.colName
		comma = ', '
	end

	if (Translate(condition) = 'ALL') then do
		condition = ''
	end
	else do
		if (Translate(Word(condition, 1)) <> 'WHERE') then do
			condition = 'WHERE ' || condition
		end
		condition = ' ' || condition
	end

    sqlStatement = 'UPDATE ' || self~dbTableName  || ' SET ' || columnValueList || condition
    self~Prepare(sqlStatement)
    self~Execute

	return

	UpdateError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Delete                                                          */
/*   - Use this method to delete an existing table row or rows.             */
/*   - Argument 1                                                           */
/*      A string specifying the value for the DELETE's WHERE clause.        */
/*                                                                          */
/*  	Note: A condition of 'ALL' must be used to delete                   */
/*  	      all rows of a table.                                          */
/*--------------------------------------------------------------------------*/
::METHOD Delete
	expose sqlca.
    use arg condition
	signal on USER SQLError NAME DeleteError

	if (Translate(condition) = 'ALL') then do
		condition = ''
	end
	else do
		if (Translate(Word(condition, 1)) <> 'WHERE') then do
			condition = 'WHERE ' || condition
		end
		condition = ' ' || condition
	end

    sqlStatement = 'DELETE FROM ' || self~dbTableName  || condition
    self~Prepare(sqlStatement)
    self~Execute

	return

	DeleteError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD TableName                                                       */
/*   - Returns the name of the database table the object represents         */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD TableName

    return self~dbTableName
	
