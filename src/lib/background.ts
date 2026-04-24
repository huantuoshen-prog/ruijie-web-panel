const DB_NAME = "ruijie-web-panel";
const STORE_NAME = "assets";
const BACKGROUND_KEY = "background-image";

function openDatabase(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    if (!("indexedDB" in window)) {
      reject(new Error("IndexedDB is not available in this browser."));
      return;
    }

    const request = window.indexedDB.open(DB_NAME, 1);

    request.onupgradeneeded = () => {
      const database = request.result;

      if (!database.objectStoreNames.contains(STORE_NAME)) {
        database.createObjectStore(STORE_NAME);
      }
    };

    request.onsuccess = () => {
      resolve(request.result);
    };

    request.onerror = () => {
      reject(request.error ?? new Error("Failed to open IndexedDB."));
    };
  });
}

function runStoreRequest<T>(
  mode: IDBTransactionMode,
  executor: (store: IDBObjectStore) => IDBRequest<T>
): Promise<T> {
  return openDatabase().then(
    (database) =>
      new Promise<T>((resolve, reject) => {
        const transaction = database.transaction(STORE_NAME, mode);
        const store = transaction.objectStore(STORE_NAME);
        const request = executor(store);

        request.onsuccess = () => {
          resolve(request.result);
        };

        request.onerror = () => {
          reject(request.error ?? new Error("IndexedDB request failed."));
        };

        transaction.oncomplete = () => {
          database.close();
        };

        transaction.onerror = () => {
          reject(transaction.error ?? new Error("IndexedDB transaction failed."));
        };
      })
  );
}

export async function loadBackgroundAsset(): Promise<Blob | null> {
  try {
    const result = await runStoreRequest("readonly", (store) => store.get(BACKGROUND_KEY));
    return result instanceof Blob ? result : null;
  } catch {
    return null;
  }
}

export async function saveBackgroundAsset(blob: Blob): Promise<void> {
  await runStoreRequest("readwrite", (store) => store.put(blob, BACKGROUND_KEY));
}

export async function clearBackgroundAsset(): Promise<void> {
  await runStoreRequest("readwrite", (store) => store.delete(BACKGROUND_KEY));
}
