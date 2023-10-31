import 'react-native-get-random-values';
import { customAlphabet } from 'nanoid';
import { IsAsset } from '../../Models';
import { justDate, sameDay } from './../DateHelpers';

import { IState } from '../IState';
import { IAction } from '../IAction';

const shortid = customAlphabet('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890_-', 7);
 
const INITIAL_STATE: IState = {
  accounts: [],
  records: [],
};

const portfolioReducer = (state = INITIAL_STATE, action: IAction) => {
  switch (action.type) {
    case 'SAVE_ACCOUNT': {
      const { accounts } = state;
      if (action.payload.id !== undefined && action.payload.id.length > 0) {
        // existing
        const account = accounts.find(x => x.id === action.payload.id);
        if(account === undefined) {
          break;
        }
        account.name = action.payload.name;
        account.provider = action.payload.provider;
        account.isAsset = action.payload.isAsset;
        account.accountType = action.payload.accountType;
      } else {
        // new
        accounts.push({
          id: shortid(),
          name: action.payload.name,
          provider: action.payload.provider,
          isAsset: action.payload.isAsset,
          accountType: action.payload.accountType,
        });
      }
      return { ...state, accounts: [...accounts] };
    }
    case 'REMOVE_ACCOUNT': {
      const accountId = action.payload.id;
      const { accounts, records } = state;
      const newAccounts = accounts.filter(x => x.id !== action.payload.id);
      const newRecords = records
        .map(r => ({
          date: r.date,
          totals: r.totals.filter(t => t.id !== accountId),
          inflows: r.inflows.filter(t => t.id !== accountId),
          outflows: r.outflows.filter(t => t.id !== accountId),
        }))
        .filter(x => x.totals.length > 0);
      return { ...state, accounts: newAccounts, records: newRecords };
    }
    case 'RESTORE_DATA': {
      const { accounts, records } = action.payload;
      const updatedRecords = (records || []).map(r => ({
        ...r,
        date: new Date(r.date),
      }));
      return { accounts, records: updatedRecords };
    }
    case 'IMPORT': {
      const json = JSON.parse(action.payload.json);
      if (
        json.categories !== undefined &&
        json.categories.length > 0 &&
        json.records !== undefined &&
        json.records.length > 0
      ) {
        const accounts = json.categories
          .filter((x: any) => x.id !== undefined)
          .map((x: any) => {
            return {
              id: shortid(),
              name: x.name,
              provider: '',
              isAsset: x.isAsset ? IsAsset.Asset : IsAsset.Liability,
            };
          });
        const offset = json.records[0].totals[0] === null ? 1 : 0;
        const records = json.records.map((x: any) => {
          return {
            date: justDate(new Date(Date.parse(x.date))),
            totals: x.totals
              .map((y, i) => {
                if (y != null) {
                  return { id: accounts[i - offset].id, amount: +y };
                }
              })
              .filter(y => y !== undefined),
            inflows: x.inflows
              .map((y, i) => {
                if (y != null) {
                  return { id: accounts[i - offset].id, amount: +y };
                }
              })
              .filter(y => y !== undefined),
            outflows: x.outflows
              .map((y, i) => {
                if (y != null) {
                  return { id: accounts[i - offset].id, amount: +y };
                }
              })
              .filter(y => y !== undefined),
          };
        });

        return Object.assign({}, state, { accounts, records });
      } else {
        return json;
      }
    }
    case 'SAVE_ENTRY': {
      const { records } = state;
      const index = records.findIndex(x =>
        sameDay(x.date, action.payload.date),
      );
      if (index >= 0) {
        // existing
        records[index].totals = action.payload.totals;
        records[index].inflows = action.payload.inflows;
        records[index].outflows = action.payload.outflows;
      } else {
        // new
        records.push({
          date: action.payload.date,
          totals: action.payload.totals,
          inflows: action.payload.inflows,
          outflows: action.payload.outflows,
        });
      }
      const newState = { ...state, records: [...records] };
      return newState;
    }
    case 'REMOVE_ENTRY': {
      const { records } = state;
      const newRecords = records.filter(x => !sameDay(x.date, action.payload));
      return { ...state, records: [...newRecords] };
    }
    case 'UPDATE': {
      const { accounts, records } = state;
      const newState = { accounts, records };
      return newState;
    }
    default:
      return state;
  }
};

export default portfolioReducer;
