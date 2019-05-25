// @flow

// Handle migration to newer versions of Yoroi

import {
  reset,
  getAddressesList
} from './lib/lovefieldDatabase';
import {
  saveLastReceiveAddressIndex,
} from './adaLocalStorage';
import LocalStorageApi from '../localStorage/index';
import {
  Logger,
} from '../../utils/logging';

const semver = require('semver');

export async function migrateToLatest(localStorageApi: LocalStorageApi) {
  const lastLaunchVersion = await localStorageApi.getLastLaunchVersion();
  Logger.info(`Starting migration for ${lastLaunchVersion}`);
  /**
   * Note: Although we don't start migration if the user is running a fresh installation
   * We still cannot be certain any key exists in localstorage
   *
   * For example, somebody may have downloaded Yoroi a long time ago
   * but only completed the language select before closing the application
   *
   * Therefore, you need to always check that data exists before migrating it
   */

  /**
    * Note: Be careful about the kinds of migrations you do here.
    * You are essentially swapping the app state under the hood
    * Therefore mobx may not notice the change as expected
    */

  const migrationMap: { [ver: string]: (() => Promise<void>) } = {
    '=0.0.1': async () => await testMigration(localStorageApi),
    '<1.4.0': bip44Migration
  };

  for (const key of Object.keys(migrationMap)) {
    if (semver.satisfies(lastLaunchVersion, key)) {
      Logger.info(`Migration started for ${key}`);
      await migrationMap[key]();
    }
  }
}

/**
 * We use this as a dummy migration so that our tests can verify migration is working correctly
 */
async function testMigration(localStorageApi: LocalStorageApi): Promise<void> {
  // changing the locale is something we can easily detect from our tests
  Logger.info(`Starting testMigration`);
  // Note: mobx will not notice this change until you refresh
  await localStorageApi.setUserLocale('ja-JP');
}

/**
 * Previous version of Yoroi were not BIP44 compliant
 * Notably, it didnt scan 20 addresses ahead of the last used address.
 * This causes desyncs when you use Yoroi either on multiple computers with the same wallet
 * or you use the same wallet on Chrome + mobile.
 */
async function bip44Migration(): Promise<void> {
  Logger.info(`Starting bip44Migration`);
  const addresses = await getAddressesList();
  if (!addresses || addresses.length === 0) {
    return;
  }
  /**
   * We used to consider all addresses in the DB as explicitly generated by the user
   * However, BIP44 requires us to also store 20 addresses after the last used address
   * Therefore the highest index in the old format is the heightest generated for new format
   */
  const maxIndex = Math.max(
    ...addresses
      .filter(address => address.change === 0)
      .map(address => address.index),
    0
  );

  // if we had more than one address, then the WALLET key must exist in localstorage
  saveLastReceiveAddressIndex(maxIndex);

  /**
   * Once we've saved the receive address, we dump the DB entirely
   * We need to do this since old wallets may have incorrect history
   * Due to desync issue caused by the incorrect bip44 implementation
   */
  reset();
}
