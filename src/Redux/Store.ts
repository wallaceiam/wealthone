import { createStore, applyMiddleware } from 'redux';
import { persistStore, persistReducer } from 'redux-persist';
import logger from 'redux-logger';
import createSensitiveStorage from 'redux-persist-sensitive-storage';

import rootReducer from './PortfolioReducer';


const persistConfig = {
  key: 'data',
  storage: createSensitiveStorage({
    keychainService: 'myKeychain',
    sharedPreferencesName: 'mySharedPrefs',
  }),
};

const persistedReducer = persistReducer(persistConfig, rootReducer);

export const store = createStore(persistedReducer, applyMiddleware(logger));

export const persistor = persistStore(store);

export const dispatch = (action) => store.dispatch(action);
