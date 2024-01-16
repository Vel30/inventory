forward bool: IsEqual1DArray(const array1[], const array2[], size1 = sizeof(array1), size2 = sizeof(array2));

bool: IsEqual1DArray(const array1[], const array2[], size1 = sizeof(array1), size2 = sizeof(array2)) {
  if (size1 != size2) {
    return false;
  }

  for (new i; i < size1; i++) {
    if (array1[i] != array2[i]) {
      return false;
    }
  }
  return true;
}
