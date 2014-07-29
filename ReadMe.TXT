                          ORexx/SQL Object Framework
                    Copyright (C) 1997 - 1998, John Blumel.
                   -----------------------------------------
		
                                
+ What is the ORexx/SQL Object Framework?


The ORexx/SQL Object Framework is a set of ORexx classes which encapsulate 
Mark Hessling's Rexx/SQL interface to SQL databases available from:

    http://www.lightlink.com/hessling/

The Rexx/SQL interface provides cross platform (OS/2, UNIX, Win 95/NT),
RDBMS independent (too many to list here, see the web page) access to
SQL databases through a loadable external rexx library. The ORexx/SQL
Object Framework extends this functionality by providing an extensible
Object Oriented interface to Rexx/SQL on platforms with ORexx 
implementations (OS/2, Win 95/NT & Linux). The Framework further 
simplifies SQL database access by managing database connections and 
queries for the programmer and through its built in error handling 
facilities.  

The framework can be used in two ways, either as an OO wrapper for the 
Rexx/SQL interface or as a Streams based interface to a SQL database.
Either of these interfaces can be used as the basis for more complex, 
reusable, application specific classes.

When used as wrapper classes, you create connection, table and result table 
objects as needed and use the methods provided by these objects to query and
update database tables. This gives you access to the entire functionality of 
the Rexx/SQL interface.

When using the Streams interface, you create SQLStream objects which create
and manage other SQL objects as needed. SQLStream objects allow you to 
access a database using an interface similar to that which standard Stream 
objects provide.

In addition to providing an OO interface to Rexx/SQL, the classes have built 
in exception handling which can be customized or overridden. Using the 
Framework's exception handling eliminates the need for inline error checking
and allows the programmer to write code which is easier to read and maintain. 

The ORexx/SQL Object Framework was developed and tested on Windows NT with 
an Oracle server. If you are using a different platform or database and
experience problems using ORexx/SQL Objects let me know and I'll try
to incorporate any necessary changes into future versions or pass on your
problems to Mark Hessling if appropriate.
     
                           
+ The ORexx/SQL Object Framework License

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


+ What's new in version 1.1

1. The SQLInstanceCounter metaclass has been eliminated and its functionality
has been incorporated into the SQLObject class
 

+ Using the ORexx/SQL Object Framework

1. The ORexx/SQL Object Framework can either be installed in your 
application directory or, if you will be using it with multiple 
applications, you can install it in a common directory which you add 
to your PATH. (If you are not using a file system which supports long file 
names you will need to change the class definition file names to file 
names which are supported. You will also need to modify any ::REQUIRES 
statements in the class definition files to use these new names.)

2. a. To use the framework as an OO wrapper for the Rexx/SQL interface,
      add the following ::REQUIRES statement to the end of the ORexx 
      program which will use the framework:

         ::REQUIRES 'SQLObj.frm'

   b. To use the framework as a Streams based database interface,
      add the following ::REQUIRES statement to the end of the ORexx 
      program which will use the framework:

         ::REQUIRES 'SQLStream.cls'

3. If you wish to enable exception handling, add the following lines to
the beginning of your ORexx program:

   signal on ERROR
   call on USER SQLError NAME SQLException

and the following line at the end of your program, before any directives:

   SQLException: call SQLError Condition("O")

4. If you wish to override the included exception handling, you can 
modify the "SQLException" routine to perform whatever processing you
wish to occur. Errors which occur in object Init methods will, however, 
continue to be handled by the ::ROUTINE defined in the 'SQLError.rtn'
file. You will have to modify this routine if you wish to override all 
exception handling.

5. You do not need to load (or unload) the Rexx/SQL functions as this is
handled automatically by the ORexx/SQL Object Framework. 

6. Before creating SQLTable or SQLResultTable objects you will need a
SQLConnection object. SQLConnection objects are created as follows:

myConnection = .SQLConnection~new(userID, password, database, host)

You can now pass this SQLConnection object to the SQLTable and 
SQLResultTable classes to create instances of those classes. The number
of SQLConnection objects you may create is limited by the number of
connections allowed by your database.

7. SQLTable & SQLResultTable objects may be created as follows:

myTable = .SQLTable~new(myConnection, 'a_table')

myResultTable = .SQLResultTable~new(myConnection, 'SELECT * FROM a_table')

8. SQLStream objects are created similarly to SQLConnection objects:

myStream = .SQLStream~new(userID, password, database, host)

9. Following are some quick examples of how to use SQLTable and
SQLResultTable objects. For more detailed information, consult the
ORexx/SQL Object Framework Reference (ClassRef).

/******************************************************************
* Using SQLTable objects
******************************************************************/
myConnection = .SQLConnection~new(userID, password, database, host)
myTable = .SQLTable~new(myConnection, 'a_table')

row.col_1 = 23
row.col_2 = "'some value'" 
/* NOTE: use "' & '" around non-numeric fields */

myTable~insert(row.)
myConnection~commit
drop row.

myTable~delete('col_1 = 23')
myConnection~commit

drop myTable
drop myConnection

/******************************************************************
* Using SQLResultTable objects
******************************************************************/
myConnection = .SQLConnection~new(userID, password, database, host)
myResultTable = .SQLResultTable~new(myConnection, 'SELECT * FROM a_table')~~Open
                      
do forever
    thisRow. = myResultTable~fetch
    if thisRow. = .nil then leave
    say 'col_1 =' thisRow.col_1
    say 'col_2 =' thisRow.col_2
end                                    
                      
myResultTable~reopen
do forever
    thisRow. = myResultTable~fetch
    if thisRow. = .nil then leave
    say 'col_1 = 'thisRow.col_1', col_2 = 'thisRow.col_2
end                                    

drop myResultTable
drop myConnection


10. Following are the examples above rewritten to using SQLStream objects. 
For more detailed information, consult the ORexx/SQL Object Framework 
Reference (ClassRef).

/******************************************************************
* Using SQLStream objects
******************************************************************/
dbStream = .SQLStream~new(userID, password, database, host)~~Open

row.col_1 = 23
row.col_2 = "'some value'" 
/* NOTE: use "' & '" around non-numeric fields */

dbStream~Out('insert', 'a_table', row.)
dbStream~commit

dbStream~Out('delete', 'a_table', 'col_1 = 23')
dbStream~commit

/* define an input stream and process the result rows */
dbStream~Out('query', 'SELECT * FROM a_table')
do forever
    aRow. = dbStream~In
    if aRow. = .nil then leave
    say 'col_1 = 'aRow.col_1', col_2 = 'aRow.col_2
end                                    

/* process the result rows again using a SQLStreamSupplier object */
rows = dbStream~Supplier
do while rows~available
	aRow. = rows~item
    say 'col_1 = 'aRow.col_1', col_2 = 'aRow.col_2
	rows~next
end

/* process the result rows again using 'do over' on the SQLStream object */
do aRow. over dbStream
    say 'col_1 = 'aRow.col_1', col_2 = 'aRow.col_2
end                                    

drop dbStream

