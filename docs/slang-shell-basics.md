# Slang-shell basics

## How to switch principals in slang-shell

Slang-shell enables you to issue commands on behalf of different principals in a scenario.  To set the current principal, set the `?Self` variable to a particular keypair file name in the keypair directory.

As an alternative, you can set `?Self` to a principal's keyhash, once the principal certificate is posted.  For example, suppose the variable `A` received Alice's keyhash when Alice posted her principal certificate, e.g., with `postRawIdSet`.  Then to switch to principal Alice:

```
?Self := $A.
```

## How to save and restore the environment

You can get a list of environment variables and their values:

```
env.
```

You can save the slang-shell environment variables to a file and reload them later.

```
saveEnvTo("env.txt").
//later...
import("env.txt").
env.
```

## How to restart and continue where you left off

**To restart slang-shell**.  It is a good practice to use commands that save all returned tokens in slang-shell variables, as in the examples.  If you follow that practice, then once you quit slang-shell after you save the environment with `saveEnvTo().`  Exit with ctrl-c or `quit.`  Run slang-shell again when you are ready. Use `import` to restore the environment in the new slang-shell instance.  Then just continue where you left off.

**To restart safe-server**.  Just restart it!  The safe-server caches certificates, and it loses the cache when it restarts.   But the certificates persist in the store, so it can fetch them given their tokens.  And it has their tokens, because you save all tokens in the slang-shell and pass them to the commands as needed.


**Changing the slang scripts**.  it is OK to change the slang scripts on the fly as long as the change does not affect the content of generated certificates.  Just remember that any existing certificates do not reflect the new content: they were generated with the old scripts.

**Using multiple hosts**.  You can run the safe-server on a different host as long as all participating safe-servers share the same Riak K/V service.  

## Principals may use separate SAFE instances.

You can run these scenarios with a separate slang-shell and safe-server for each principal.  That is how SAFE should run in production.  The only wrinkle is that they often must pass tokens to one another.  Token-passing is easy in these examples because we run them in the same slang-shell with shared environment variables.

## It is safe to reissue old commands (no side effects).


If you reissue a command that constructs and posts a certificate, it generates a new certificate that overwrites the old one.  Any other certificates that linked to the old version now link to the new version. If we use the same arguments, the script generates an identical certificate, so nothing changes (scripts are deterministic). So we can freely reissue these commands.

But what if you use different arguments?  Depending on the scripts, issuing a variant of an earlier command with different arguments might or might not overwrite the old certificate, and if it does, the new version might or might not be different from the old version.  It is a good practice to incorporate parameter values into the label to prevent unexpected side effects.
