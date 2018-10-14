import { combineReducers } from 'redux';

import reduceReducers from 'reduce-reducers';

import iCloudStorage from 'react-native-icloudstore';

import { Alert } from 'react-native';

import * as shortid from 'shortid';
import { AccountTypes } from '../models/Account';
import { justDate, sameDay } from '../helpers/Date';
import { statsReducer } from './StatsReducer';
import { dataRestored } from './Actions';

import { dispatch } from './Store';

const INITIAL_STATE = {
    accounts: [],
    goals: [],
    records: [],
    stats: {}
};

const portfolioReducer = (state = INITIAL_STATE, action) => {
    switch (action.type) {
        case 'SAVE_ACCOUNT': {
            const { accounts } = state;
            if (action.payload.id !== undefined && action.payload.id.length > 0) {
                // existing
                const account = accounts.find(x => x.id === action.payload.id);
                account.name = action.payload.name;
                account.provider = action.payload.provider;
            } else {
                // new
                accounts.push({
                    id: shortid.generate(),
                    name: action.payload.name,
                    provider: action.payload.provider,
                    accountType: action.payload.accountType
                });

            }
            return { ...state, accounts: accounts };
        }
        case 'REMOVE_ACCOUNT': {
            const { accounts } = state;
            const indexOf = accounts.findIndex(x => x.id === action.payload.id);
            accounts.splice(indexOf, 1);
            return Object.assign({}, state, { accounts });
        }
        case 'BACKUP': {
            iCloudStorage.setItem('backup', JSON.stringify(state))
                .then(x => {
                    Alert.alert('iCloud Backup', 'Success: ' + JSON.stringify(x));
                })
                .catch(x => {
                    Alert.alert('iCloud Backup', JSON.stringify(x));
                });

            return state;
        }
        case 'RESTORE': {
            iCloudStorage.getItem('backup')
                .then(x => {
                    dispatch(dataRestored(JSON.parse(x)));
                })
                .catch(x => {
                    Alert.alert('iCloud Restore', JSON.stringify(x));
                });
            return state;
        }
        case 'RESTORE_DATA': {
            return action.payload;
        }
        case 'IMPORT': {
            const json = JSON.parse(action.payload.json);
            if (json.categories !== undefined && json.categories.length > 0
                && json.records !== undefined && json.records.length > 0) {
                const accounts = json.categories.filter(x => x.id !== undefined).map(x => {
                    return {
                        id: shortid.generate(),
                        name: x.name,
                        provider: '',
                        accountType: x.isAsset ? AccountTypes.Asset : AccountTypes.Liability
                    }
                });
                const offset = json.records[0].totals[0] === null ? 1 : 0;
                const records = json.records.map(x => {
                    return {
                        date: justDate(new Date(Date.parse(x.date))),
                        totals: x.totals.map((y, i) => {
                            if (y != null) {
                                return { id: accounts[i - offset].id, amount: +y }
                            }
                        }).filter(y => y != undefined),
                        inflows: x.inflows.map((y, i) => {
                            if (y != null) {
                                return { id: accounts[i - offset].id, amount: +y }
                            }
                        }).filter(y => y != undefined),
                        outflows: x.outflows.map((y, i) => {
                            if (y != null) {
                                return { id: accounts[i - offset].id, amount: +y }
                            }
                        }).filter(y => y != undefined)
                    }
                })

                return Object.assign({}, state, { accounts, records });
            }
        }
        case 'SAVE_ENTRY': {
            const { records } = state;
            const index = records.findIndex(x => sameDay(x.date, action.payload.date));
            if (index >= 0) {
                // existing
                records[index].totals = action.payload.totals;
                records[index].inflows = action.payload.inflows;
                records[index].outflows = action.payload.outflows;
            }
            else {
                // new
                records.push({
                    date: action.payload.date,
                    totals: action.payload.totals,
                    inflows: action.payload.inflows,
                    outflows: action.payload.outflows
                });

            }
            const newState = { ...state, records: records };
            return newState;
        }
        default:
            return state
    }
};

const chainReducer = (state = INITIAL_STATE, action) => {
    const newState = portfolioReducer(state, action);
    const newerState = statsReducer(newState, action);
    return newerState;
}

export default combineReducers({
    portfolio: chainReducer,
});