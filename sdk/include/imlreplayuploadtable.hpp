// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************
#ifndef _IMLREPLAYUPLOADTABLE_HPP_INCLUDED
#define _IMLREPLAYUPLOADTABLE_HPP_INCLUDED

#include "sqltype.h"

class IMLReplayRow;

/*
 * This is an interface for the table objects that will be generated by the API
 * generator.  It will be used to pass data to MLReplay by a call to
 * GetUploadTransaction.
 */
class IMLReplayUploadTable {
    public:
	virtual ~IMLReplayUploadTable( void )
	/***********************************/
	{
	}

	/*
	 * Initialize the UploadTable.
	 */
	virtual bool Init( void ) = 0;

	/*
	 * Finishes the UploadTable.
	 */
	virtual void Fini( void ) = 0;

	/*
	 * Frees all the rows from this class.
	 */
	virtual void FreeAllUploadRows( void ) = 0;

	/*
	 * Returns a row from the table.
	 */
	virtual const IMLReplayRow * GetRow( asa_uint32 rowNum ) const = 0;

	/*
	 * Returns the number of rows in the table.
	 */
	virtual asa_uint32 GetNumRows( void ) const = 0;

	/*
	 * Returns the number of inserts for the given transaction in the given
	 * synchronization in the given recorded protocol.
	 *
	 * recordedSyncNum - the synchronization number (ordinal 1) within the
	 *                   recorded protocol
	 * uploadTransNum  - the upload transaction number (ordinal 1) within
	 *                   the current synchonrization
	 */
	virtual asa_uint32 GetNumRecordedInserts( asa_uint32	recordedSyncNum,
						  asa_uint32	uploadTransNum ) const = 0;

	/*
	 * Returns the number of updates for the given transaction in the given
	 * synchronization in the given recorded protocol.
	 *
	 * recordedSyncNum - the synchronization number (ordinal 1) within the
	 *                   recorded protocol
	 * uploadTransNum  - the upload transaction number (ordinal 1) within
	 *                   the current synchonrization
	 */
	virtual asa_uint32 GetNumRecordedUpdates( asa_uint32	recordedSyncNum,
						  asa_uint32	uploadTransNum ) const = 0;

	/*
	 * Returns the number of deletes for the given transaction in the given
	 * synchronization in the given recorded protocol.
	 *
	 * recordedSyncNum - the synchronization number (ordinal 1) within the
	 *                   recorded protocol
	 * uploadTransNum  - the upload transaction number (ordinal 1) within
	 *                   the current synchonrization
	 */
	virtual asa_uint32 GetNumRecordedDeletes( asa_uint32	recordedSyncNum,
						  asa_uint32	uploadTransNum ) const = 0;
};

#endif
