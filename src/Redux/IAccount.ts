import {IAccountType} from '../Models';

export interface IAccount {
  id: string;
  name: string;
  provider: string;
  isAsset: boolean;
  accountType: IAccountType;
}
