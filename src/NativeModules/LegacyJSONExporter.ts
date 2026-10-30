import {NativeModules} from 'react-native';

export async function shareLegacyJSON(json: string): Promise<void> {
  const exporter = NativeModules.LegacyJSONExporter;
  if (!exporter) {
    throw new Error('JSON file export requires the updated iOS app build.');
  }
  await exporter.share(json, 'wealthone-backup.json');
}
