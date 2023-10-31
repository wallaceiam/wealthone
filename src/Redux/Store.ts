import {createStore, applyMiddleware, combineReducers} from 'redux';
import {persistStore, persistReducer} from 'redux-persist';
import {createLogger} from 'redux-logger';
import createCompressor from './createCompressor';
import iCloudStorage from 'react-native-icloudstore';

import {backupReducer, goalReducer, portfolioReducer} from './Reducers';
import thunk from 'redux-thunk';
import {IAction} from './IAction';

const compressor = createCompressor();

const replacer = (_key: string, value: any) =>
  Array.isArray(value) ? [] : value;

const stateTransformer = (state: any) => JSON.stringify(state, replacer);

const logger = createLogger({
  stateTransformer,
});

console.log(iCloudStorage);

const persistConfig = {
  key: 'wealthone_data',
  storage: iCloudStorage,
  transforms: [compressor],
};

const rootReducer = combineReducers({
  portfolio: portfolioReducer,
  goal: goalReducer,
  backup: backupReducer,
});

const persistedReducer = persistReducer(persistConfig, rootReducer);

export const store = createStore(
  persistedReducer,
  applyMiddleware(thunk, logger),
);

export const persistor = persistStore(store);

export const dispatch = (action: IAction) => store.dispatch(action);
