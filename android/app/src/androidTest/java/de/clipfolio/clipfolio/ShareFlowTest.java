package de.clipfolio.clipfolio;

import android.content.Context;
import android.content.Intent;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.uiautomator.By;
import androidx.test.uiautomator.UiDevice;
import androidx.test.uiautomator.UiObject2;
import androidx.test.uiautomator.Until;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class ShareFlowTest {
    private final UiDevice device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());

    private UiObject2 label(String text) {
        return device.wait(Until.findObject(By.descContains(text)), 10000);
    }

    @Test public void shareLinkIntoWorkout() {
        Context context = InstrumentationRegistry.getInstrumentation().getTargetContext();
        String url = "https://clipfolio.invalid/clipfolio-test-" + System.currentTimeMillis();
        Intent share = new Intent(Intent.ACTION_SEND)
            .setPackage(context.getPackageName())
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, "Mein Trainingsvideo " + url)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        assertNotNull(share.resolveActivity(context.getPackageManager()));
        context.startActivity(share);
        UiObject2 link = device.wait(Until.findObject(By.text(url)), 30000);
        assertNotNull("Geteilter Link im Editor", link);
        UiObject2 workout = label("Workout");
        assertNotNull(workout);
        workout.click();
        UiObject2 save = device.findObject(By.desc("Speichern"));
        for (int i = 0; save == null && i < 5; i++) {
            int x = device.getDisplayWidth() / 2;
            device.swipe(x, device.getDisplayHeight()*3/4, x, device.getDisplayHeight()/3, 20);
            device.waitForIdle();
            save = device.findObject(By.desc("Speichern"));
        }
        assertNotNull("Speichern sichtbar", save);
        save.click();
        assertNotNull("Zurück in der Mediathek", label("Meine Mediathek"));
        UiObject2 folder = label("Workout");
        assertNotNull(folder);
        folder.click();
        assertNotNull("Gespeicherter Link im gewählten Ordner", label(url));
    }
}
