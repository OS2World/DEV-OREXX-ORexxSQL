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
/*  SQLResultTable.cls  -  SQLResultTable class                             */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library  . . . . . Rexx/SQL interface by Mark Hessling        */
/*                                http://www.lightlink.com/hessling/        */
/*    SQLWorkArea.cls  . . . . . SQLWorkArea class                          */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLWorkArea.cls'

/*--------------------------------------------------------------------------*/
/* SQLResultTable Class definition                                          */
/*--------------------------------------------------------------------------*/
::CLASS SQLResultTable SUBCLASS SQLWorkArea PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLResultTable Class Methods                                             */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init CLASS                                                      */
/*   - Removes the Execute & ExecuteWithBind methods inherited from         */
/*     SQLWorkArea.                                                         */
/*--------------------------------------------------------------------------*/
::METHOD Init CLASS

    self~define('EXECUTE')
    self~define('EXECUTEWITHBIND')

	forward class (super)

/*--------------------------------------------------------------------------*/
/* SQLResultTable instance variables                                        */
/*--------------------------------------------------------------------------*/
::METHOD bindDataTypes. ATTRIBUTE PRIVATE
::METHOD bindValues. ATTRIBUTE PRIVATE
::METHOD isOpen ATTRIBUTE PRIVATE

/*--------------------------------------------------------------------------*/
/* SQLResultTable Instance Methods                                          */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init                                                            */
/*   - This method is automatically invoked when the SQLResultTable class   */
/*     is sent a NEW message. The SELECT statement provided will be         */
/*     prepared and the result table will be ready for opening. Both        */
/*     arguments are required, if either is omitted, an exception will be   */
/*     raised.                                                              */
/*   - Argument 1                                                           */
/*      A SQLConnection object.                                             */
/*   - Argument 2                                                           */
/*      A valid SELECT statement.                                           */
/*--------------------------------------------------------------------------*/
::METHOD Init
	expose sqlca.
    use arg theConnection, theQuery
	signal on USER SQLError NAME InitError

    self~bindDataTypes. = .nil
    self~bindValues. = .nil
    self~isOpen = 0

    self~Init:super(theConnection)

	if (\Var('theQuery')) then do
		sqlca.class = self~class
		sqlca.exception = 'Init failed - query statement not supplied'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    self~Prepare(theQuery)

	return

	InitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Open                                                            */
/*   - Use this method to open the SQLResultTable.                          */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Open
	expose sqlca.
	signal on USER SQLError NAME OpenError

    self~bindDataTypes. = .nil
   	self~bindValues. = .nil

    self~connection~MakeDefault

    if (SQLOpen(self~statementName) == 0) then do
        self~isOpen = 1
    end
    else do
		sqlca.class = self~class
		sqlca.exception = 'Open failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
    end

	return

	OpenError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD OpenWithBind                                                    */
/*   - Use this method to open the SQLResultTable and supply bind values    */
/*     for the SELECT statement.                                            */
/*   - Argument 1                                                           */
/*      A Stem object containing the bind data types.                       */
/*   - Argument 2                                                           */
/*      A Stem object containing the bind values.                           */
/*--------------------------------------------------------------------------*/
::METHOD OpenWithBind
	expose sqlca.
    use arg dt., bv.
	signal on USER SQLError NAME OpenWithBindError

    self~connection~MakeDefault

    if (SQLOpen(self~statementName, "dt.", "bv.") == 0) then do
	    self~bindDataTypes. = dt.
	   	self~bindValues. = bv.
        self~isOpen = 1
    end
    else do
		sqlca.class = self~class
		sqlca.exception = 'OpenWithBind failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
    end

	return

	OpenWithBindError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Close                                                           */
/*   - Use this method to close the SQLResultTable.                         */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Close
	expose sqlca.
	signal on USER SQLError NAME CloseError

	if self~isOpen then do
	    self~connection~MakeDefault

	    if (SQLClose(self~statementName) == 0) then do
	        self~isOpen = 0
	    end
	    else do
			sqlca.class = self~class
			sqlca.exception = 'Close failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
   		end
	end

	return

	CloseError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD ReOpen                                                          */
/*   - Use this method to close and then re-open a SQLResultTable.          */
/*     If the SQLResultTable was opened with bind values, the same values   */
/*     will be used to re-open it.                                          */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD ReOpen
	expose sqlca.
	signal on USER SQLError NAME ReOpenError

    self~connection~MakeDefault

	if (self~bindValues. == .nil) then do
    	SQLrc = SQLOpen(self~statementName)
	end
	else do
    	dt. = self~bindDataTypes.
    	bv. = self~bindValues.
    	SQLrc = SQLOpen(self~statementName, "dt.", "bv.")
	end

    if (SQLrc == 0) then do
        self~isOpen = 1
    end
    else do
        self~isOpen = 0
		sqlca.class = self~class
		sqlca.exception = 'ReOpen failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
    end

	return

	ReOpenError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Fetch                                                           */
/*   - Use this method to fetch the next available row from the             */
/*     SQLResultTable. The row is returned in a Stem object indexed by      */
/*     column name.                                                         */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Fetch
	expose sqlca.
	signal on USER SQLError NAME FetchError

    self~connection~MakeDefault

	if (\self~isOpen) then self~Open

    SQLrc = SQLFetch(self~statementName)
	
	select
		when (SQLrc > 0) then do
	        interpret 'return 'self~statementName'.'
    	end
		when (SQLrc == 0) then do
	        return .nil
    	end
		otherwise do
			sqlca.class = self~class
			sqlca.exception = 'Fetch failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return

	FetchError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD FetchRowSet                                                     */
/*   - Use this method to fetch multiple rows from the SQLResultTable.      */
/*     The rows are returned as an Array of Stem objects indexed by         */
/*     column name.                                                         */
/*   - Argument 1                                                           */
/*      An integer specifying the number of rows to fetch. This             */
/*      parameter is optional and ommitting it or specifying a value of     */
/*      0 will result in all remaining (i.e., yet unfetched) rows being     */
/*      returned.                                                           */
/*--------------------------------------------------------------------------*/
::METHOD FetchRowSet
	expose sqlca.
    use arg maxRows
	signal on USER SQLError NAME FetchRowSetError

	if (\Var('maxRows')) then maxRows = 0
	rowSet = .array~new(maxRows)

    self~connection~MakeDefault

	if (\self~isOpen) then self~Open

	if (maxRows == 0) then do
		i = 0
   		do forever
    		SQLrc = SQLFetch(self~statementName)
   			if (SQLrc <= 0) then leave
			i = i + 1
	    	interpret 'rowSet['i'] = 'self~statementName'.~copy'
   		end
	end
	else do 
   		do maxRows
    		SQLrc = SQLFetch(self~statementName)
   			if (SQLrc <= 0) then leave
	    	interpret 'rowSet['i'] = 'self~statementName'.~copy'
   		end
	end
    if (SQLrc < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'FetchRowSet failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end		
    
    return rowSet

	FetchRowSetError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD GetLongColumnData                                               */
/*   - This method returns part (or all) of a column from the               */
/*     current fetched row.                                                 */
/*   - Argument 1                                                           */
/*      The name of the column.                                             */
/*   - Argument 2                                                           */
/*      The, 1 based, starting byte from which to retrieve data.            */
/*   - Argument 3                                                           */
/*      The number of bytes to retrieve.                                    */
/*--------------------------------------------------------------------------*/
::METHOD GetLongColumnData
	expose sqlca.
    use arg columnName, startPosition, length
	signal on USER SQLError NAME GetLongColumnDataError

    self~connection~MakeDefault

    bytes = SQLGetData(self~statementName, columnName, startPosition, length)

    if (bytes >= 0) then do
		Interpret 'return 'self~statementName'.'columnName
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'GetLongColumnData failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
    end

	return .nil

	GetLongColumnDataError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD WriteLongColumnToFile                                           */
/*   - Use this method to write a column, from the current fetched row,     */
/*     to an operating system file. The number of bytes written is          */
/*     returned.                                                            */
/*   - Argument 1                                                           */
/*      The name of the column.                                             */
/*   - Argument 2                                                           */
/*      The name of the file to which the data should be written.           */
/*--------------------------------------------------------------------------*/
::METHOD WriteLongColumnToFile
	expose sqlca.
    use arg columnName, outFile
	signal on USER SQLError NAME WriteLongColumnToFileError

    self~connection~MakeDefault

    bytesWritten = SQLGetData(self~statementName, 0, 0, outFile)

    if (bytesWritten >= 0) then do
		return bytesWritten
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'WriteLongColumnToFile failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
    end

	WriteLongColumnToFileError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Describe                                                        */
/*   - This method returns a Stem object containing information             */
/*     describing the SQLResultTable. For a description of the Stem         */
/*     object returned, see the Rexx/SQL documentation for the              */
/*     SQLDescribe() function.                                              */
/*   - No arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Describe
	expose sqlca.
	signal on USER SQLError NAME DescribeError

    self~connection~MakeDefault

    if (SQLDescribe(self~statementName, "descStem") >= 0) then do
        return descStem.
    end
    else do
		sqlca.class = self~class
		sqlca.exception = 'Describe failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
    end

	return

	DescribeError: raise propagate
