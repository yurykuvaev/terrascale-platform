# Runbook: ArgoCD application rollback

When a sync goes wrong (workload broken, platform component crashlooping,
config drift), roll back through ArgoCD rather than reverting commits.
The git revert is for the audit trail; the ArgoCD rollback is for the
seconds it actually takes to recover.

## When to roll back vs. roll forward

Roll back when:

- A platform component (cert-manager, ESO, AWS LB Controller) is
  CrashLoopBackOff and the cause isn't obvious in 5 minutes.
- A tenant Application is firing customer-impacting alerts.

Roll forward when:

- Cluster-scoped CRDs were added in the last sync — rollbacks don't
  remove CRDs.
- The fix is well-understood and a small commit away.

## Roll back via UI

1. Open the Application page.
2. **History and Rollback** → pick the last Synced/Healthy revision.
3. Click **Rollback**. Argo applies that revision and pauses auto-sync
   to prevent the next reconcile from re-pulling main.

## Roll back via CLI

```bash
argocd app history <app-name>
argocd app rollback <app-name> <revision>
```

The revision is Argo's internal counter, not the git SHA — `app history`
prints both.

## Re-enable sync after rollback

Once you've rolled back, automatic sync stays paused so the next git push
to main doesn't re-deploy the broken state. Re-enable only after the fix
is merged:

```bash
argocd app set <app-name> --sync-policy automated
```

## Rolling back a Helm chart pinned to git

The umbrella charts under `kubernetes/platform/<env>/` reference upstream
charts by version. To pin to the previous chart while you investigate:

1. Bump the dependency version in `Chart.yaml` to the previous one.
2. Run `helm dependency update` locally to refresh `Chart.lock`.
3. Commit, PR, merge.
4. ArgoCD rolls forward to the older chart.

This is preferable to a rollback because it leaves the new git head
representing the cluster's actual state.

## What if the rollback itself doesn't take

If `argocd app rollback` reports Synced but pods don't come back:

- The chart may have a Job hook that already ran. Delete the Job manually:
  `kubectl -n <ns> delete job <hook-job>`.
- A CRD upgrade may have left orphaned objects of an old apiVersion. Clean
  them with `kubectl get -A` and delete the offending objects.
- As a last resort, `argocd app delete <app> --cascade=false` and let the
  ApplicationSet re-create the Application from scratch on the next sync.
