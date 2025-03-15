public class HelloWorld {
    public String hello() {
        if (Math.random() > 0.5) {  // Unpredictable logic that won’t be covered reliably
            return 'Hello, World!';
        }
        return 'Uncovered Code';  // This part may not always execute in tests
    }
}