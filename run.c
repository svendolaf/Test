#include <stdio.h>
#include <windows.h>

int main (int argc, char * argv[]) {

    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    DWORD dwCreationFlags;
    DWORD exit_code;

    dwCreationFlags = CREATE_NO_WINDOW;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (CreateProcess(argv[1], argv[2], 0 ,0, 0, dwCreationFlags, 0, 0, &si, &pi)) {

        WaitForSingleObject( pi.hProcess, INFINITE );

        GetExitCodeProcess(pi.hProcess, &exit_code);

        printf("Exit code: %d\n", exit_code);

        CloseHandle( pi.hProcess );
        CloseHandle( pi.hThread );
    }

}
