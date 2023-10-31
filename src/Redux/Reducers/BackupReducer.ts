const INITIAL_STATE = {
  lastBackupDate: undefined,
};

const backupReducer = (state = INITIAL_STATE, action) => {
  switch (action.type) {
    case 'BACKUP_SUCCESS':
      return {...state, lastBackupDate: action.payload};
    case 'LAST_BACKUP_DATE':
      return {...state, lastBackupDate: action.payload};
  }
  return state;
};

export default backupReducer;
