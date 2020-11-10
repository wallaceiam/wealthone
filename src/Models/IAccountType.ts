import { Types } from "./Types";

export interface IAccountType {
  id: number,
  name: string,
  isAsset: boolean,
  type?: Types
};