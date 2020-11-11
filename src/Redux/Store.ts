import { createStore, applyMiddleware, combineReducers } from 'redux';
import { persistStore, persistReducer } from 'redux-persist';
import logger from 'redux-logger';
import createSensitiveStorage from 'redux-persist-sensitive-storage';

import portfolioReducer from './PortfolioReducer';
import goalReducer from './GoalReducer';
import backupReducer from './BackupReducer';
import thunk from 'redux-thunk';

const persistConfig = {
  key: 'data',
  storage: createSensitiveStorage({
    keychainService: 'keychainService',
    sharedPreferencesName: 'ca.mymojo.wealthone',
  }),
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

export const dispatch = (action) => store.dispatch(action);
