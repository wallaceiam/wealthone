import { Alert } from 'react-native';
import iCloudStorage from 'react-native-icloudstore';
import { IGoalInput } from './IGoalInput';

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

export const saveGoal = (input: IGoalInput) => ({
  type: 'SAVE_GOAL',
  payload: input,
});

const backupSuccessful = (lastBackupDate) => {
  Alert.alert('iCloud Backup', 'Your data has been backed up to iCloud');

  return {
    type: 'BACKUP_SUCCESS',
    payload: lastBackupDate,
  };
};

const backupFailed = (err) => {
  console.error(err);

  Alert.alert(
    'iCloud Backup',
    'An error occured while trying to backup to iCloud',
  );

  return {
    type: 'BACKUP_FAILED',
    payload: null,
  };
};

const restoreSuccessful = () => {
  Alert.alert('iCloud restore', 'Your data has been restored from iCloud');

  return {
    type: 'RESTORE_SUCCESSFUL',
    payload: null,
  };
};

const restoreFailedNoData = () => {
  Alert.alert('iCloud restore', 'There is no data to restore');

  return {
    type: 'RESTORE_FAILED',
    payload: 'No Data',
  };
};

const restoreFailed = (err) => {
  console.error(err);

  Alert.alert(
    'iCloud restore',
    'An error occured while trying to restore from iCloud',
  );

  return {
    type: 'RESTORE_FAILED',
    payload: err,
  };
};

export const backup = () => {
  return (dispatch, getState) => {
    const { goal, portfolio } = getState();
    const now = new Date();
    const lastBackupDate = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        now.getUTCHours(),
        now.getUTCMinutes(),
        now.getUTCSeconds(),
      ),
    );
    iCloudStorage
      .setItem(
        'wealthone',
        JSON.stringify({ goal, ...portfolio, ts: lastBackupDate }),
      )
      .then((_) => {
        dispatch(backupSuccessful(lastBackupDate));
      })
      .catch((err) => {
        dispatch(backupFailed(err));
      });
  };
};

export const restore = () => {
  return (dispatch) => {
    iCloudStorage
      .getItem('wealthone')
      .then((x) => {
        if (x !== undefined && x !== null) {
          const json = JSON.parse(x);
          dispatch(restoreData(json));
          dispatch(restoreSuccessful());
        } else {
          dispatch(restoreFailedNoData());
        }
      })
      .catch((err) => {
        dispatch(restoreFailed(err));
      });
  };
};

const lastBackupDate = (date) => ({
  type: 'LAST_BACKUP_DATE',
  payload: date,
});

export const fetchLastBackupDate = () => {
  return (dispatch) => {
    iCloudStorage
      .getItem('wealthone')
      .then((x) => {
        if (x !== undefined && x !== null) {
          const json = JSON.parse(x);
          dispatch(lastBackupDate(json.backup.lastBackupDate));
        }
      })
      .catch((_) => {});
  };
};

export const restorePrevious = () => {
  return (dispatch) => {
    iCloudStorage
      .getItem('backup')
      .then((x) => {
        if (x !== undefined && x !== null) {
          const json = JSON.parse(x);
          const keys = Object.keys(json);
          Alert.alert('iCloud restore', `${[...keys]}`);
          const { accounts, records, goal } = json;
          dispatch(restoreData({ accounts, records, goal: goal.input }));
          dispatch(restoreSuccessful());
        } else {
          dispatch(restoreFailedNoData());
        }
      })
      .catch((err: Error) => {
        dispatch(restoreFailed(err));
      });
  };
};

export const update = () => ({
  type: 'UPDATE',
});

export const restoreData = (payload) => ({
  type: 'RESTORE_DATA',
  payload,
});

export const rehydrate = (key, payload) => ({
  type: 'persist/REHYDRATE_1',
  key,
  payload,
});

export const importJson = (text: string) => ({
  type: 'IMPORT',
  payload: { json: text },
});

export const saveEntry = (payload) => ({
  type: 'SAVE_ENTRY',
  payload,
});

export const removeEntry = (date) => ({
  type: 'REMOVE_ENTRY',
  payload: date,
});
