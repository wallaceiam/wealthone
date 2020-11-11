import { toUtc } from './DateHelpers';

const INITIAL_STATE = {
  birthDate: toUtc(new Date(1978, 11, 26)),
  currentAge: 40,
  earnings: 55000,

  contributions: 0,
  pension: 0,
  investmentStyle: 3,
  lifeStyle: 40,
  retirementAge: 65,
};

const goalReducer = (state = INITIAL_STATE, action) => {
  if (action.type.startsWith('@@redux') || action.type.startsWith('persist')) {
    return state;
  }
  switch (action.type) {
    case 'SAVE_GOAL':
      return { ...state, ...action.payload };
    case 'RESTORE_DATA': {
      const { goal } = action.payload;
      return { ...state, ...goal };
    }
  }
  return state;
};

export default goalReducer;
