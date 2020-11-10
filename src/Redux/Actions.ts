export const saveAccount = (account) => ({
  type: 'SAVE_ACCOUNT',
  payload: {
    id: account.id,
    name: account.name,
    provider: account.provider,
    isAsset: account.isAsset,
    accountType: account.accountType,
  },
});

export const removeAccount = (id) => ({
  type: 'REMOVE_ACCOUNT',
  payload: { id: id },
});

export const saveGoal = (input) => ({
  type: 'SAVE_GOAL',
  payload: {
    input,
  },
});

export const removeGoal = (id) => ({
  type: 'REMOVE_GOAL',
  payload: { id: id },
});

export const backup = () => ({
  type: 'BACKUP',
});

export const backupSync = (payload) => ({
  type: 'BACKUP_SYNC',
  payload: payload,
});

export const restore = () => ({
  type: 'RESTORE',
});

export const update = () => ({
  type: 'UPDATE',
});

export const restoreData = (payload) => ({
  type: 'RESTORE_DATA',
  payload: payload,
});

export const restoreSync = (payload) => ({
  type: 'RESTORE_SYNC',
  payload: payload,
});

export const importJson = (text) => ({
  type: 'IMPORT',
  payload: { json: text },
});

export const saveEntry = (payload) => ({
  type: 'SAVE_ENTRY',
  payload: payload,
});

export const calc = (payload) => ({
  type: 'CALC',
  payload: payload,
});
