import { IsAsset } from "./Account";
import { IAccountType } from "./IAccountType";

export const AccountTypes: IAccountType[] = [
  // assets
  { id: 0, name: 'Cash', isAsset: IsAsset.Asset },
  { id: 1, name: 'Savings', isAsset: IsAsset.Asset },
  { id: 2, name: 'General Investment Account', isAsset: IsAsset.Asset },
  { id: 3, name: 'ISA', isAsset: IsAsset.Asset },
  { id: 4, name: 'LISA', isAsset: IsAsset.Asset },
  { id: 5, name: 'Pension', isAsset: IsAsset.Asset },
  { id: 6, name: 'Property', isAsset: IsAsset.Asset },

  //liabilities
  { id: 7, name: 'Mortgage', isAsset: IsAsset.Liability },
  { id: 8, name: 'Credit Card', isAsset: IsAsset.Liability },
  { id: 9, name: 'Loan', isAsset: IsAsset.Liability },
];