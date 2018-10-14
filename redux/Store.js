import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import { persistStore, persistReducer } from 'redux-persist'
import storage from 'redux-persist/lib/storage' // defaults to localStorage for web and AsyncStorage for react-native

import rootReducer from './PortfolioReducer';

import logger from 'redux-logger'

const persistConfig = {
    key: 'data',
    storage,
}

const persistedReducer = persistReducer(persistConfig, rootReducer)

export const store = createStore(persistedReducer, applyMiddleware(logger));
export const persistor = persistStore(store);

export const dispatch = (action) => store.dispatch(action);
